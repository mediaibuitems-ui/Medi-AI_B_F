using System.Text;
using System.Text.Json;
using Backend_APIs.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend_APIs.Controllers
{
    public class SymptomAnalyzerRequestDto
    {
        public List<string> SelectedSymptoms { get; set; } = new();
        public string OtherSymptoms { get; set; } = string.Empty;
        public string Severity { get; set; } = string.Empty;
        public string Duration { get; set; } = string.Empty;
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
        public async Task<IActionResult> EvaluateSymptoms([FromBody] SymptomAnalyzerRequestDto request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                              ?? User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("Invalid token.");
            }

            var apiKey = _configuration["Gemini:ApiKey"];
            if (string.IsNullOrEmpty(apiKey) || apiKey.Contains("INSERT_GEMINI_API_KEY_HERE"))
            {
                apiKey = _configuration["Groq:ApiKey"];
                if (string.IsNullOrEmpty(apiKey) || apiKey.Contains("INSERT_GROQ_API_KEY_HERE"))
                    return StatusCode(500, "API Key is not configured in appsettings.json.");
            }

            var selectedSymptomsStr = string.Join(", ", request.SelectedSymptoms);

            string systemPrompt = $@"
Act as an expert clinical triage assistant.
CRITICAL RULES:
1. DO NOT provide a definitive medical diagnosis. State that this is a preliminary analysis.
2. DO NOT prescribe restricted or prescription medications.
3. YOU MAY suggest standard Over-The-Counter (OTC) remedies for symptom relief.
4. Always provide a clear home-care procedure.

Analyze the following symptoms and respond STRICTLY in the following JSON format without any markdown formatting or extra text:
{{
  ""possibleCondition"": ""[General Malaise]"",
  ""confidenceLevel"": ""[70%]"",
  ""severity"": ""[Mild, Moderate, or Severe]"",
  ""urgencyMessage"": ""[Mild urgency. Home care and monitoring may help.]"",
  ""recommendations"": [""[Rest]"", ""[Monitor symptoms]""],
  ""homeCareGuidance"": [""[Hydrate well]"", ""[Rest]""],
  ""recommendedDoctorType"": ""[General Physician]""
}}

Patient Symptoms: {selectedSymptomsStr}
Other Symptoms: {request.OtherSymptoms}
Patient Reported Severity: {request.Severity}
Duration: {request.Duration}";
            
            try 
            {
                bool isGroq = apiKey.StartsWith("gsk_");
                string replyContent = string.Empty;

                if (isGroq)
                {
                    var requestBody = new
                    {
                        model = "llama-3.3-70b-versatile",
                        messages = new[]
                        {
                            new { role = "system", content = systemPrompt }
                        },
                        response_format = new { type = "json_object" }
                    };

                    _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
                    var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
                    var response = await _httpClient.PostAsync("https://api.groq.com/openai/v1/chat/completions", content);
                    
                    var responseString = await response.Content.ReadAsStringAsync();
                    if (!response.IsSuccessStatusCode)
                    {
                        _logger.LogError($"Groq API Error: {responseString}");
                        return StatusCode(500, "Failed to analyze symptoms via Groq API.");
                    }

                    using var doc = JsonDocument.Parse(responseString);
                    replyContent = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "{}";
                }
                else
                {
                    var requestBody = new
                    {
                        contents = new[]
                        {
                            new { parts = new[] { new { text = systemPrompt } } }
                        },
                        generationConfig = new
                        {
                            responseMimeType = "application/json"
                        }
                    };

                    var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
                    var response = await _httpClient.PostAsync($"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={apiKey}", content);
                    
                    var responseString = await response.Content.ReadAsStringAsync();
                    if (!response.IsSuccessStatusCode)
                    {
                        _logger.LogError($"Gemini API Error: {responseString}");
                        return StatusCode(500, "Failed to analyze symptoms via Gemini API.");
                    }

                    using var doc = JsonDocument.Parse(responseString);
                    var candidates = doc.RootElement.GetProperty("candidates")[0];
                    replyContent = candidates.GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString() ?? "{}";
                }

                var jsonResult = JsonSerializer.Deserialize<SymptomAnalyzerResponseDto>(replyContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (jsonResult == null)
                {
                    return StatusCode(500, "Failed to parse AI response.");
                }

                var analysisRecord = new AiSymptomAnalysis
                {
                    UserId = userId,
                    SelectedSymptoms = selectedSymptomsStr,
                    OtherSymptoms = request.OtherSymptoms,
                    SeverityInput = request.Severity,
                    Duration = request.Duration,
                    PossibleCondition = jsonResult.PossibleCondition,
                    ConfidenceLevel = jsonResult.ConfidenceLevel,
                    CalculatedSeverity = jsonResult.Severity,
                    UrgencyMessage = jsonResult.UrgencyMessage,
                    Recommendations = JsonSerializer.Serialize(jsonResult.Recommendations),
                    HomeCareGuidance = JsonSerializer.Serialize(jsonResult.HomeCareGuidance),
                    RecommendedDoctorType = jsonResult.RecommendedDoctorType,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AiSymptomAnalyses.Add(analysisRecord);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, data = jsonResult });
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
                var history = await _context.AiSymptomAnalyses
                    .Where(a => a.UserId == userId)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new
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
                        Recommendations = string.IsNullOrEmpty(a.Recommendations) ? new List<string>() : JsonSerializer.Deserialize<List<string>>(a.Recommendations, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }),
                        HomeCareGuidance = string.IsNullOrEmpty(a.HomeCareGuidance) ? new List<string>() : JsonSerializer.Deserialize<List<string>>(a.HomeCareGuidance, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }),
                        a.RecommendedDoctorType,
                        a.CreatedAt
                    })
                    .ToListAsync();

                return Ok(new { success = true, data = history });
            }
            catch (Exception ex)
            {
                _logger.LogError($"SymptomAnalyzer History Error: {ex.Message}");
                return StatusCode(500, "An internal error occurred while retrieving history.");
            }
        }
    }
}

