using System.Text;
using System.Text.Json;
using Backend_APIs.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Microsoft.AspNetCore.RateLimiting;

namespace Backend_APIs.Controllers
{
    public class SymptomAnalyzerRequestDto
    {
        public List<string> SelectedSymptoms { get; set; } = new();
        public string OtherSymptoms { get; set; } = string.Empty;
        public string Severity { get; set; } = string.Empty;
        public string Duration { get; set; } = string.Empty;
        public int? Age { get; set; }
        public string? BiologicalSex { get; set; }
        public string? Onset { get; set; }
        public List<string> RedFlags { get; set; } = new();
        public List<string> ExistingConditions { get; set; } = new();
        public string? CurrentMedications { get; set; }
        public string? Allergies { get; set; }
        public string? PregnancyStatus { get; set; }
    }

    public class SymptomAnalyzerResponseDto
    {
        public string PossibleCondition { get; set; } = string.Empty;
        public string ConfidenceLevel { get; set; } = string.Empty;
        public string Severity { get; set; } = string.Empty;
        public string UrgencyMessage { get; set; } = string.Empty;
        public List<string> Recommendations { get; set; } = new();
        public List<string> HomeCareGuidance { get; set; } = new();
        public string RecommendedDoctorType { get; set; } = string.Empty;
        public string TriageTier { get; set; } = string.Empty;
        public string WhenToSeekCare { get; set; } = string.Empty;
    }

    public class InterviewStartRequestDto
    {
        public List<string> RedFlags { get; set; } = new();
        public int? Age { get; set; }
        public string? BiologicalSex { get; set; }
        public string? PregnancyStatus { get; set; }
        public List<string> ExistingConditions { get; set; } = new();
        public string? CurrentMedications { get; set; }
        public string? Allergies { get; set; }
    }

    public class InterviewAnswerRequestDto
    {
        public Guid SessionId { get; set; }
        public string Answer { get; set; } = string.Empty;
    }

    [Route("api/analyzer")]
    [ApiController]
    [Authorize]
    public class SymptomAnalyzerController : ControllerBase
    {
        private readonly MediaidbContext _context;
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<SymptomAnalyzerController> _logger;

        public SymptomAnalyzerController(MediaidbContext context, IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<SymptomAnalyzerController> logger)
        {
            _context = context;
            _httpClient = httpClientFactory.CreateClient();
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost("evaluate")]
        [EnableRateLimiting("AnalyzerLimiter")]
        public async Task<IActionResult> EvaluateSymptoms([FromBody] SymptomAnalyzerRequestDto request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                              ?? User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("Invalid token.");
            }

            var apiKey = _configuration["Groq:ApiKey"] ?? _configuration["NaraRouter:ApiKey"] ?? _configuration["Gemini:ApiKey"];
            if (string.IsNullOrEmpty(apiKey) || apiKey.StartsWith("INSERT_") || apiKey.Contains("INSERT_"))
            {
                return StatusCode(500, new { success = false, message = "AI API Key is not configured. Please add Groq__ApiKey to Railway environment variables." });
            }

            var selectedSymptomsStr = string.Join(", ", request.SelectedSymptoms);

            var emergencyKeywords = new[] { "can't breathe", "cannot breathe", "chest pain", "suicidal", "kill myself", "heart attack", "stroke" };
            bool hasRedFlagKeywords = !string.IsNullOrEmpty(request.OtherSymptoms) && 
                emergencyKeywords.Any(k => request.OtherSymptoms.Contains(k, StringComparison.OrdinalIgnoreCase));

            if ((request.RedFlags != null && request.RedFlags.Any()) || hasRedFlagKeywords)
            {
                var redFlagsDetail = request.RedFlags != null ? string.Join(", ", request.RedFlags) : "";
                if (hasRedFlagKeywords) redFlagsDetail += " [Keyword Match in Other Symptoms]";

                var emergencyRecord = new AiSymptomAnalysis
                {
                    UserId = userId,
                    SelectedSymptoms = selectedSymptomsStr,
                    OtherSymptoms = request.OtherSymptoms,
                    SeverityInput = request.Severity,
                    Duration = request.Duration,
                    Age = request.Age,
                    BiologicalSex = request.BiologicalSex,
                    Onset = request.Onset,
                    RedFlagsTriggered = true,
                    RedFlagsDetail = redFlagsDetail.Trim(),
                    ExistingConditions = string.Join(", ", request.ExistingConditions ?? new List<string>()),
                    CurrentMedications = request.CurrentMedications,
                    Allergies = request.Allergies,
                    PregnancyStatus = request.PregnancyStatus,
                    Status = "emergency_routed",
                    TriageTier = "seek_care_urgently",
                    UrgencyMessage = "Emergency routing triggered based on reported red flags.",
                    CreatedAt = DateTime.UtcNow
                };
                _context.AiSymptomAnalyses.Add(emergencyRecord);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, isEmergency = true, message = "Emergency red flags detected. Please seek immediate medical attention." });
            }

            string systemPrompt = $@"
Act as an expert clinical triage assistant.
CRITICAL RULES:
1. DO NOT provide a definitive medical diagnosis. State clearly that this is a preliminary analysis.
2. DO NOT prescribe restricted or prescription medications.
3. NEVER name a specific medication, brand, or drug class (not even OTC). ONLY describe general self-care categories (e.g. 'rest', 'hydration', 'warm compress').
4. Always provide a clear home-care procedure.

Analyze the following patient context and respond STRICTLY in the following JSON format without any markdown formatting or extra text:
{{
  ""triageTier"": ""[self_care | see_a_doctor_soon | seek_care_urgently]"",
  ""possibleCondition"": ""[General Malaise - phrased as a possibility, not a diagnosis]"",
  ""confidenceLevel"": ""[low | moderate | high]"",
  ""severity"": ""[Mild, Moderate, or Severe]"",
  ""urgencyMessage"": ""[Mild urgency. Home care and monitoring may help.]"",
  ""recommendations"": [""[Rest]"", ""[Monitor symptoms]""],
  ""homeCareGuidance"": [""[Hydrate well]"", ""[Rest]""],
  ""whenToSeekCare"": ""[Warning signs to watch for]"",
  ""recommendedDoctorType"": ""[General Physician]""
}}

Patient Context:
Age: {request.Age?.ToString() ?? "Not provided"}
Biological Sex: {request.BiologicalSex ?? "Not provided"}
Pregnancy Status: {request.PregnancyStatus ?? "N/A"}
Existing Conditions: {(request.ExistingConditions != null && request.ExistingConditions.Any() ? string.Join(", ", request.ExistingConditions) : "None")}
Current Medications: {request.CurrentMedications ?? "None"}
Allergies: {request.Allergies ?? "None"}

Symptoms and Current Episode:
Selected Symptoms: {selectedSymptomsStr}
Other Symptoms: {request.OtherSymptoms}
Onset: {request.Onset ?? "Not provided"}
Patient Reported Severity: {request.Severity}
Duration: {request.Duration}";

            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
                var requestBody = new
                {
                    model = "llama-3.1-8b-instant", // Groq model name
                    messages = new[]
                    {
                        new { role = "system", content = systemPrompt }
                    },
                    response_format = new { type = "json_object" }
                };

                _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
                var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("https://api.groq.com/openai/v1/chat/completions", content, cts.Token);

                var responseString = await response.Content.ReadAsStringAsync(cts.Token);
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"Groq API Error: {responseString}");
                    return StatusCode(500, new { success = false, message = $"Failed to analyze symptoms via AI API. Error: {responseString}" });
                }

                using var doc = JsonDocument.Parse(responseString);
                string replyContent = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "{}";

                // Clean markdown code blocks if any
                replyContent = replyContent.Trim();
                if (replyContent.StartsWith("```json", StringComparison.OrdinalIgnoreCase))
                {
                    replyContent = replyContent.Substring(7);
                }
                else if (replyContent.StartsWith("```"))
                {
                    replyContent = replyContent.Substring(3);
                }
                if (replyContent.EndsWith("```"))
                {
                    replyContent = replyContent.Substring(0, replyContent.Length - 3);
                }
                replyContent = replyContent.Trim();

                var jsonResult = JsonSerializer.Deserialize<SymptomAnalyzerResponseDto>(replyContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (jsonResult == null || string.IsNullOrEmpty(jsonResult.TriageTier))
                {
                    return StatusCode(500, new { success = false, message = $"Failed to parse AI response or missing TriageTier. Raw output: {replyContent}" });
                }

                // Basic check for drug names in free text to enforce Rule 3
                var combinedText = string.Join(" ", jsonResult.Recommendations) + " " + string.Join(" ", jsonResult.HomeCareGuidance) + " " + jsonResult.UrgencyMessage;
                var commonDrugKeywords = new[] { "ibuprofen", "tylenol", "advil", "aspirin", "paracetamol", "acetaminophen", "antibiotic", "medication", "pill", "tablet" };
                if (commonDrugKeywords.Any(k => combinedText.Contains(k, StringComparison.OrdinalIgnoreCase)))
                {
                     _logger.LogWarning("AI response contained potential drug names. Rejecting response.");
                     return StatusCode(500, new { success = false, message = "AI response violated safety constraints regarding medication recommendations." });
                }

                var analysisRecord = new AiSymptomAnalysis
                {
                    UserId = userId,
                    SelectedSymptoms = selectedSymptomsStr,
                    OtherSymptoms = request.OtherSymptoms,
                    SeverityInput = request.Severity,
                    Duration = request.Duration,
                    Age = request.Age,
                    BiologicalSex = request.BiologicalSex,
                    Onset = request.Onset,
                    ExistingConditions = string.Join(", ", request.ExistingConditions ?? new List<string>()),
                    CurrentMedications = request.CurrentMedications,
                    Allergies = request.Allergies,
                    PregnancyStatus = request.PregnancyStatus,
                    PossibleCondition = jsonResult.PossibleCondition,
                    ConfidenceLevel = jsonResult.ConfidenceLevel,
                    CalculatedSeverity = jsonResult.Severity,
                    UrgencyMessage = jsonResult.UrgencyMessage,
                    Recommendations = JsonSerializer.Serialize(jsonResult.Recommendations),
                    HomeCareGuidance = JsonSerializer.Serialize(jsonResult.HomeCareGuidance),
                    RecommendedDoctorType = jsonResult.RecommendedDoctorType,
                    TriageTier = jsonResult.TriageTier,
                    WhenToSeekCare = jsonResult.WhenToSeekCare,
                    Status = "analyzed",
                    CreatedAt = DateTime.UtcNow
                };

                _context.AiSymptomAnalyses.Add(analysisRecord);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, data = jsonResult });
            }
            catch (TaskCanceledException)
            {
                _logger.LogWarning("SymptomAnalyzer Evaluate Error: Request timed out.");
                return StatusCode(504, "The AI analyzer took too long to respond. Please try again.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"SymptomAnalyzer Evaluate Error: {ex.Message}");
                return StatusCode(500, "An internal error occurred during symptom analysis.");
            }
        }
        [HttpGet("history")]
        public async Task<IActionResult> GetHistory()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                              ?? User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("Invalid token.");
            }

            try
            {
                var rawHistory = await _context.AiSymptomAnalyses
                    .Where(a => a.UserId == userId)
                    .OrderByDescending(a => a.CreatedAt)
                    .ToListAsync();

                var history = rawHistory.Select(a => new
                {
                    a.Id,
                    a.SelectedSymptoms,
                    a.OtherSymptoms,
                    a.SeverityInput,
                    a.Duration,
                    a.PossibleCondition,
                    a.ConfidenceLevel,
                    a.CalculatedSeverity,
                    a.UrgencyMessage,
                    Recommendations = TryParseJsonList(a.Recommendations),
                    HomeCareGuidance = TryParseJsonList(a.HomeCareGuidance),
                    a.RecommendedDoctorType,
                    a.CreatedAt
                })
                    .ToList();

                return Ok(new { success = true, data = history });
            }
            catch (Exception ex)
            {
                _logger.LogError($"SymptomAnalyzer History Error: {ex.Message}");
                return StatusCode(500, "An internal error occurred while retrieving history.");
            }
        }

        private static List<string> TryParseJsonList(string json)
        {
            if (string.IsNullOrEmpty(json)) return new List<string>();
            try
            {
                return JsonSerializer.Deserialize<List<string>>(json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new List<string>();
            }
            catch
            {
                return new List<string> { "[Data could not be loaded for this record]" };
            }
        }

        [HttpPost("interview/start")]
        [EnableRateLimiting("AnalyzerLimiter")]
        public async Task<IActionResult> StartInterview([FromBody] InterviewStartRequestDto request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                              ?? User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid token.");

            var redFlagTriggered = request.RedFlags != null && request.RedFlags.Any();
            var session = new AiSymptomInterviewSession
            {
                UserId = userId,
                RedFlagAnswers = request.RedFlags != null ? string.Join(", ", request.RedFlags) : null,
                RedFlagTriggered = redFlagTriggered,
                Status = redFlagTriggered ? "emergency_routed" : "in_progress",
                Age = request.Age,
                BiologicalSex = request.BiologicalSex,
                PregnancyStatus = request.PregnancyStatus,
                ExistingConditions = string.Join(", ", request.ExistingConditions ?? new List<string>()),
                CurrentMedications = request.CurrentMedications,
                Allergies = request.Allergies,
                CreatedAt = DateTime.UtcNow
            };

            if (redFlagTriggered)
            {
                _context.AiSymptomInterviewSessions.Add(session);
                await _context.SaveChangesAsync();
                return Ok(new { success = true, isEmergency = true, sessionId = session.Id, message = "Emergency red flags detected." });
            }

            var apiKey = _configuration["Groq:ApiKey"] ?? _configuration["Gemini:ApiKey"];
            if (string.IsNullOrEmpty(apiKey) || apiKey.StartsWith("INSERT_"))
                return StatusCode(500, new { success = false, message = "AI API Key is not configured." });

            string systemPrompt = GetInterviewSystemPrompt(session);
            var messages = new List<object> { new { role = "system", content = systemPrompt } };

            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
                var requestBody = new { model = "llama-3.1-8b-instant", messages, response_format = new { type = "json_object" } };

                _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
                var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("https://api.groq.com/openai/v1/chat/completions", content, cts.Token);

                var responseString = await response.Content.ReadAsStringAsync(cts.Token);
                if (!response.IsSuccessStatusCode)
                    return StatusCode(500, new { success = false, message = "Failed to start interview via AI API." });

                string replyContent = JsonDocument.Parse(responseString).RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "{}";
                replyContent = CleanJson(replyContent);

                var jsonResult = JsonSerializer.Deserialize<Dictionary<string, object>>(replyContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                if (jsonResult == null || !jsonResult.ContainsKey("action") || jsonResult["action"].ToString() != "ask")
                    return StatusCode(500, new { success = false, message = "Failed to parse initial AI question." });

                string firstQuestion = jsonResult["question"].ToString();
                
                var transcript = new List<Dictionary<string, string>>
                {
                    new Dictionary<string, string> { { "question", firstQuestion }, { "answer", "" } }
                };
                session.Transcript = JsonSerializer.Serialize(transcript);

                _context.AiSymptomInterviewSessions.Add(session);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, isEmergency = false, sessionId = session.Id, question = firstQuestion });
            }
            catch (Exception ex)
            {
                _logger.LogError($"StartInterview Error: {ex.Message}");
                return StatusCode(500, "An internal error occurred.");
            }
        }

        [HttpPost("interview/answer")]
        [EnableRateLimiting("AnalyzerLimiter")]
        public async Task<IActionResult> AnswerInterview([FromBody] InterviewAnswerRequestDto request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                              ?? User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid token.");

            var session = await _context.AiSymptomInterviewSessions.FirstOrDefaultAsync(s => s.Id == request.SessionId && s.UserId == userId);
            if (session == null || session.Status != "in_progress")
                return BadRequest(new { success = false, message = "Invalid or completed session." });

            var transcript = string.IsNullOrEmpty(session.Transcript) ? new List<Dictionary<string, string>>() 
                : JsonSerializer.Deserialize<List<Dictionary<string, string>>>(session.Transcript);

            // Fill in the answer for the most recent question
            if (transcript.Any() && string.IsNullOrEmpty(transcript.Last()["answer"]))
            {
                transcript.Last()["answer"] = request.Answer;
            }

            var emergencyKeywords = new[] { "can't breathe", "cannot breathe", "chest pain", "suicidal", "kill myself", "heart attack", "stroke" };
            if (emergencyKeywords.Any(k => request.Answer.Contains(k, StringComparison.OrdinalIgnoreCase)))
            {
                session.Status = "emergency_routed";
                session.Transcript = JsonSerializer.Serialize(transcript);
                await _context.SaveChangesAsync();
                return Ok(new { success = true, isEmergency = true, message = "Emergency red flags detected." });
            }

            var apiKey = _configuration["Groq:ApiKey"] ?? _configuration["Gemini:ApiKey"];
            string systemPrompt = GetInterviewSystemPrompt(session);
            var messages = new List<object> { new { role = "system", content = systemPrompt } };

            foreach (var turn in transcript)
            {
                messages.Add(new { role = "assistant", content = turn["question"] });
                if (!string.IsNullOrEmpty(turn["answer"]))
                {
                    messages.Add(new { role = "user", content = turn["answer"] });
                }
            }

            // Turn cap check
            if (transcript.Count(t => !string.IsNullOrEmpty(t["answer"])) >= 10)
            {
                 messages.Add(new { role = "system", content = "You must now output the final analysis. Do not ask any more questions." });
            }

            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
                var requestBody = new { model = "llama-3.1-8b-instant", messages, response_format = new { type = "json_object" } };

                _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
                var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("https://api.groq.com/openai/v1/chat/completions", content, cts.Token);

                var responseString = await response.Content.ReadAsStringAsync(cts.Token);
                if (!response.IsSuccessStatusCode)
                    return StatusCode(500, new { success = false, message = "Failed to communicate with AI API." });

                string replyContent = JsonDocument.Parse(responseString).RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "{}";
                replyContent = CleanJson(replyContent);

                var jsonResult = JsonSerializer.Deserialize<Dictionary<string, object>>(replyContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                
                if (jsonResult != null && jsonResult.ContainsKey("action") && jsonResult["action"].ToString() == "complete")
                {
                    session.Status = "completed";
                    session.CompletedAt = DateTime.UtcNow;
                    var analysisJson = JsonSerializer.Serialize(jsonResult["analysis"]);
                    
                    // Validate basic drug constraint
                    var commonDrugKeywords = new[] { "ibuprofen", "tylenol", "advil", "aspirin", "paracetamol", "acetaminophen", "antibiotic", "medication", "pill", "tablet" };
                    if (commonDrugKeywords.Any(k => analysisJson.Contains(k, StringComparison.OrdinalIgnoreCase)))
                    {
                         _logger.LogWarning("AI response contained potential drug names. Rejecting response.");
                         return StatusCode(500, new { success = false, message = "AI response violated safety constraints regarding medication recommendations." });
                    }

                    session.FinalAnalysis = analysisJson;
                    session.Transcript = JsonSerializer.Serialize(transcript);
                    await _context.SaveChangesAsync();
                    return Ok(new { success = true, action = "complete", analysis = jsonResult["analysis"], transcript = transcript });
                }
                else if (jsonResult != null && jsonResult.ContainsKey("action") && jsonResult["action"].ToString() == "ask")
                {
                    string nextQuestion = jsonResult["question"].ToString();
                    transcript.Add(new Dictionary<string, string> { { "question", nextQuestion }, { "answer", "" } });
                    session.Transcript = JsonSerializer.Serialize(transcript);
                    await _context.SaveChangesAsync();
                    return Ok(new { success = true, action = "ask", question = nextQuestion });
                }

                return StatusCode(500, new { success = false, message = "Failed to parse AI response." });
            }
            catch (Exception ex)
            {
                _logger.LogError($"AnswerInterview Error: {ex.Message}");
                return StatusCode(500, "An internal error occurred.");
            }
        }

        private string GetInterviewSystemPrompt(AiSymptomInterviewSession session)
        {
            return $@"You are conducting a brief clinical intake interview, one question at a time.
You already know the patient has no emergency red-flag symptoms (already screened).

Rules:
1. Ask exactly ONE clear, specific question per turn. No compound questions.
2. Base each question on everything answered so far — follow up on what's relevant, don't repeat ground already covered.
3. Ask about things a doctor would actually want to know: symptom character, triggers/relievers, related symptoms, relevant history, medications, allergies — adapt based on what's already been said.
4. After you have enough information to give useful guidance (usually 6-10 questions), stop asking and instead output the final compiled analysis.
5. NEVER name a specific medication, drug, or brand at any point, in questions or in the final analysis.
6. NEVER state a diagnosis as fact — only possibilities, clearly labeled as such.
7. If the patient's answer at any point describes something urgent (severe pain, breathing trouble, safety concerns), stop the interview immediately and output the final analysis with triageTier = ""seek_care_urgently"", clearly explaining why.

Respond in STRICT JSON only, one of these two shapes:
Continuing: {{""action"": ""ask"", ""question"": ""string""}}
Finishing:  {{""action"": ""complete"", ""analysis"": {{ ""triageTier"": ""self_care | see_a_doctor_soon | seek_care_urgently"", ""summary"": ""..."", ""possibleCondition"": ""..."", ""confidenceLevel"": ""low | moderate | high"", ""recommendations"": [""...""], ""homeCareGuidance"": [""...""], ""whenToSeekCare"": ""..."", ""recommendedDoctorType"": ""..."" }} }}

Patient Context:
Age: {session.Age?.ToString() ?? "Not provided"}
Biological Sex: {session.BiologicalSex ?? "Not provided"}
Pregnancy Status: {session.PregnancyStatus ?? "N/A"}
Existing Conditions: {(string.IsNullOrEmpty(session.ExistingConditions) ? "None" : session.ExistingConditions)}
Current Medications: {session.CurrentMedications ?? "None"}
Allergies: {session.Allergies ?? "None"}";
        }

        private string CleanJson(string replyContent)
        {
            replyContent = replyContent.Trim();
            if (replyContent.StartsWith("```json", StringComparison.OrdinalIgnoreCase))
                replyContent = replyContent.Substring(7);
            else if (replyContent.StartsWith("```"))
                replyContent = replyContent.Substring(3);
            if (replyContent.EndsWith("```"))
                replyContent = replyContent.Substring(0, replyContent.Length - 3);
            return replyContent.Trim();
        }
    }
}

