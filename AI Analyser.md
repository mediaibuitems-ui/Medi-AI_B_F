# AI Analyzer Architecture & Flow

This document outlines the complete architecture, data flow, and code implementation of the AI Symptom Analyzer feature in the Medi-AI application.

## System Flow Architecture

The AI Analyzer involves communication between the Flutter frontend, the C# .NET Backend, and the Groq API (using the `llama-3.1-8b-instant` model).

### 1. Frontend Flow (Flutter / Dart)
1. **User Input:** The user accesses the Symptom Analyzer screen and inputs their symptoms (selecting from common ones or typing custom ones), severity, and duration.
2. **Input Processing:** The `AiSymptomInputController` validates the inputs.
3. **API Request:** The frontend makes a `POST` request to the backend at `/api/analyzer/evaluate` with the payload (symptoms, otherSymptoms, severity, duration).
4. **Result Handling:** Upon a successful response, the controller navigates the user to the `AiSymptomResultController` screen, passing the JSON response data as navigation arguments.
5. **Next Steps:** The `AiSymptomResultController` parses the AI response (Possible condition, urgency, recommendations, recommended doctor type) and displays it. The user can then tap "Book Appointment" which passes the recommended doctor type to the booking screen.

### 2. Backend Flow (C# .NET)
1. **Endpoint:** `SymptomAnalyzerController` handles the `POST /api/analyzer/evaluate` request.
2. **Authentication & Rate Limiting:** The request is authorized using JWT claims (to get `userId`) and rate-limited to prevent API abuse.
3. **Prompt Construction:** The controller builds a system prompt instructing the AI to act as a clinical triage assistant. It embeds the patient's symptoms, severity, and duration into the prompt, and strictly requests a JSON format response.
4. **External API Call:** The backend sends the prompt to the Groq API (`https://api.groq.com/openai/v1/chat/completions`) using the `llama-3.1-8b-instant` model.
5. **Response Parsing:** The response content is extracted, stripped of any markdown formatting (like ```json), and deserialized into a `SymptomAnalyzerResponseDto`.
6. **Database Persistence:** The raw request data and the AI's analysis results are stored in the database (`AiSymptomAnalyses` table) linked to the user's ID for history tracking.
7. **Return Response:** The backend returns the parsed AI evaluation to the frontend.

---

## Code Implementation Details

### Backend Code

**File:** `Medi_AI_Backend_railway/Backend-APIs/Controllers/SymptomAnalyzerController.cs`

```csharp
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

                if (jsonResult == null)
                {
                    return StatusCode(500, new { success = false, message = $"Failed to parse AI response. Raw output: {replyContent}" });
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
    }
}
```

---

### Frontend Code

**File:** `lib/app/modules/student/symptom_analyzer/ai_symptom_input_controller.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_ai/app/services/api_service.dart';

class AiSymptomInputController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final selectedSymptoms = <String>[].obs;
  final selectedSeverity = ''.obs;
  final durationController = TextEditingController();
  final otherSymptomsController = TextEditingController();
  final isLoading = false.obs;
  final formKey = GlobalKey<FormState>();

  final List<String> commonSymptoms = [
    'Fever',
    'Cough',
    'Headache',
    'Fatigue',
    'Sore Throat',
    'Body Aches',
    'Nausea',
    'Dizziness',
    'Shortness of Breath',
    'Chest Pain'
  ];

  final List<String> severityLevels = ['Mild', 'Moderate', 'Severe'];

  void toggleSymptom(String symptom) {
    if (selectedSymptoms.contains(symptom)) {
      selectedSymptoms.remove(symptom);
    } else {
      selectedSymptoms.add(symptom);
    }
  }

  void selectSeverity(String severity) {
    selectedSeverity.value = severity;
  }

  Future<void> analyzeSymptoms() async {
    if (selectedSymptoms.isEmpty &&
        otherSymptomsController.text.trim().isEmpty) {
      Get.snackbar(
          'Input Required', 'Please select or enter at least one symptom.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100);
      return;
    }
    if (selectedSeverity.value.isEmpty) {
      Get.snackbar('Input Required', 'Please select the severity.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100);
      return;
    }
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    try {
      final requestData = {
        'selectedSymptoms': selectedSymptoms.toList(),
        'otherSymptoms': otherSymptomsController.text.trim(),
        'severity': selectedSeverity.value,
        'duration': durationController.text.trim(),
      };

      final response =
          await _apiService.post('/analyzer/evaluate', data: requestData);

      if (response.success && response.data != null) {
        Get.toNamed('/symptom-analyzer-result', arguments: response.data);
      } else {
        Get.snackbar('Analysis Failed', response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    durationController.dispose();
    otherSymptomsController.dispose();
    super.onClose();
  }
}
```

**File:** `lib/app/modules/student/symptom_analyzer/ai_symptom_result_controller.dart`

```dart
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class AiSymptomResultController extends GetxController {
  final Map<String, dynamic> resultData = Get.arguments ?? {};

  String get possibleCondition => resultData['possibleCondition'] ?? 'Unknown';
  String get confidenceLevel => resultData['confidenceLevel'] ?? 'N/A';
  String get severity => resultData['severity'] ?? 'Unknown';
  String get urgencyMessage => resultData['urgencyMessage'] ?? '';
  List<String> get recommendations => _parseStringList(resultData['recommendations']);
  List<String> get homeCareGuidance => _parseStringList(resultData['homeCareGuidance']);

  List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    if (data is String) {
      return [data];
    }
    return [];
  }
  String get recommendedDoctorType =>
      resultData['recommendedDoctorType'] ?? 'General Physician';

  void bookAppointment() {
    // Navigate to the book appointment screen and pass the recommended doctor type if needed
    Get.toNamed(AppRoutes.bookAppointment,
        arguments: {'doctorType': recommendedDoctorType});
  }
}
```
