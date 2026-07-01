using Backend_APIs.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using System.Text;

namespace Backend_APIs.Controllers
{
    [Route("api/healthanalyzer")]
    [ApiController]
    [Authorize]
    public class HealthAnalyzerController : ControllerBase
    {
        private readonly MediaidbContext _context;
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<HealthAnalyzerController> _logger;

        public HealthAnalyzerController(MediaidbContext context, HttpClient httpClient, IConfiguration configuration, ILogger<HealthAnalyzerController> logger)
        {
            _context = context;
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost("assess")]
        public async Task<IActionResult> AssessSymptoms([FromBody] HealthAssessmentRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Symptoms))
                return BadRequest("Symptoms cannot be empty.");

            var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                return Unauthorized("Invalid user token.");

            var apiKey = _configuration["Gemini:ApiKey"];
            if (string.IsNullOrEmpty(apiKey))
            {
                // Fallback to Groq API Key if Gemini is not explicitly set, but warn the dev.
                apiKey = _configuration["Groq:ApiKey"];
                if (string.IsNullOrEmpty(apiKey))
                    return StatusCode(500, "Gemini API Key is not configured in appsettings.json.");
            }

            var systemPrompt = @"Act as Med-AI, an expert clinical triage assistant.
Your job is to analyze the patient's symptoms and provide a safe, structured, and actionable preliminary care plan.
CRITICAL RULES:
1. DO NOT provide a definitive medical diagnosis. State that this is a preliminary analysis.
2. DO NOT prescribe restricted or prescription medications (e.g., antibiotics, strong painkillers).
3. YOU MAY suggest standard Over-The-Counter (OTC) remedies for symptom relief.
4. Always provide a clear home-care procedure.

Analyze the following symptoms and respond STRICTLY in the following JSON format without any markdown formatting or extra text:
{
  ""triageLevel"": ""[Choose one: EMERGENCY, URGENT, ROUTINE, or SELF-CARE]"",
  ""analysis"": ""[A 2-3 sentence explanation]"",
  ""suggestedOtcMedicine"": ""[List 1-2 standard over-the-counter remedies, or write 'None']"",
  ""homeCareProcedure"": [
    ""[Step 1]"",
    ""[Step 2]""
  ],
  ""doctorRecommendation"": ""[What specific specialist should they book an appointment with]""
}

Patient Symptoms: " + request.Symptoms;
            
            try 
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
                
                // If the user's key is actually a Groq key (format differs), this URL will fail. 
                // We'll catch and log it clearly.
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"Gemini API Error: {responseString}");
                    return StatusCode(500, "Failed to analyze symptoms via Gemini API. Please ensure a valid Google Gemini API key is configured.");
                }

                using var doc = JsonDocument.Parse(responseString);
                var candidates = doc.RootElement.GetProperty("candidates")[0];
                var replyContent = candidates.GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString();

                var jsonResult = JsonSerializer.Deserialize<HealthAnalyzerResponseDto>(replyContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                var assessment = new AiHealthAssessment
                {
                    UserId = userId,
                    RawSymptoms = request.Symptoms,
                    TriageLevel = jsonResult?.TriageLevel ?? "ROUTINE",
                    ClinicalAnalysis = jsonResult?.Analysis ?? "Unable to analyze.",
                    SuggestedMedicine = jsonResult?.SuggestedOtcMedicine,
                    HomeCarePlan = JsonSerializer.Serialize(jsonResult?.HomeCareProcedure ?? new List<string>()),
                    RecommendedDoctor = jsonResult?.DoctorRecommendation
                };

                _context.AiHealthAssessments.Add(assessment);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = "Symptoms analyzed successfully.",
                    data = assessment
                });
            }
            catch(Exception ex)
            {
                _logger.LogError(ex, "Error during health assessment.");
                return StatusCode(500, "An internal error occurred.");
            }
        }
    }

    public class HealthAssessmentRequest
    {
        public string Symptoms { get; set; }
    }

    public class HealthAnalyzerResponseDto
    {
        public string TriageLevel { get; set; }
        public string Analysis { get; set; }
        public string SuggestedOtcMedicine { get; set; }
        public List<string> HomeCareProcedure { get; set; }
        public string DoctorRecommendation { get; set; }
    }
}
