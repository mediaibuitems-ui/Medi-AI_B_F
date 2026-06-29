using Backend_APIs.DTOs;
using Backend_APIs.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Net.Http.Headers;
using System.Text;

namespace Backend_APIs.Services
{
    public class GroqAgentService : IGroqAgentService
    {
        private readonly HttpClient _httpClient;
        private readonly MediaidbContext _context;
        private readonly IConfiguration _configuration;
        private readonly ILogger<GroqAgentService> _logger;

        public GroqAgentService(HttpClient httpClient, MediaidbContext context, IConfiguration configuration, ILogger<GroqAgentService> logger)
        {
            _httpClient = httpClient;
            _context = context;
            _configuration = configuration;
            _logger = logger;

            var apiKey = _configuration["Groq:ApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
            {
                _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            }
            _httpClient.BaseAddress = new Uri("https://api.groq.com/openai/v1/");
        }

        public async Task<string> ExecuteAgentAsync(int userId, List<AgentChatMessage> conversationHistory)
        {
            // 1. Implicit Profile Injection
            var user = await _context.Users.FindAsync(userId);
            if (user == null) throw new Exception("User not found");

            int age = 0;
            if (user.DateOfBirth.HasValue)
            {
                var today = DateOnly.FromDateTime(DateTime.Today);
                age = today.Year - user.DateOfBirth.Value.Year;
                if (user.DateOfBirth.Value > today.AddYears(-age)) age--;
            }

            string systemPrompt = $@"You are a Senior Medical AI Assistant. 
You are speaking to {user.FullName}, a {age}-year-old {user.Gender}. 
Use this physiological context for your clinical analysis without asking them for their age or gender.

CRITICAL TRIAGE WORKFLOW:
1. INITIAL GREETING & FOLLOW-UP: On the first turn, start exactly with: 'Welcome {user.FullName}! Disclaimer: I am an AI, not a doctor. Please consult a professional for emergencies.' Then, ask 1 or 2 brief follow-up questions to gather more context about their symptoms.
2. SYMPTOM ANALYSIS & ADVICE: Once you have enough context, provide a comprehensive but easy-to-understand analysis of their symptoms based on your medical knowledge.
3. TREATMENT & DIETARY PLAN: You MUST suggest general over-the-counter (OTC) medicines for symptom relief. You MUST also explicitly provide a list of recommended foods to eat and foods to avoid based strictly on their specific condition. Do not use generic templates; tailor the advice dynamically.
4. DOCTOR APPOINTMENT SUGGESTION (FINAL STEP): At the very end of your analysis and advice, politely ask if they would like to book an appointment with a doctor for a proper checkup. If they agree, use the 'get_doctor_schedules' tool to find available doctors, present them to the user, and if they select one, use 'execute_final_booking'. NEVER suggest a doctor or try to book an appointment before completing the symptom analysis and dietary advice.
5. CLINICAL DISCLAIMER: Conclude your analysis with a polite disclaimer that your advice does not replace a physical medical diagnosis.
";

            var groqMessages = new List<object>
            {
                new { role = "system", content = systemPrompt }
            };

            foreach (var msg in conversationHistory)
            {
                groqMessages.Add(new { role = msg.Role, content = msg.Content });
            }

            var requestBody = new
            {
                model = "llama-3.3-70b-versatile",
                messages = groqMessages,
                tools = GetTools(),
                tool_choice = "auto"
            };

            var reply = await RunAgentLoop(userId, requestBody);

            // Persist Chat History
            try
            {
                var latestSession = await _context.Symptomchecks
                    .Where(s => s.UserId == userId && s.CreatedAt >= DateTime.UtcNow.AddHours(-1))
                    .OrderByDescending(s => s.CreatedAt)
                    .FirstOrDefaultAsync();

                var fullTranscript = JsonSerializer.Serialize(conversationHistory);
                var initialSymptomContent = conversationHistory.FirstOrDefault(m => m.Role == "user")?.Content ?? "Chat Session";
                var initialSymptom = JsonSerializer.Serialize(new[] { initialSymptomContent });

                if (latestSession != null)
                {
                    latestSession.ChatTranscript = fullTranscript;
                    latestSession.Symptoms = initialSymptom;
                }
                else
                {
                    var newSession = new Symptomcheck
                    {
                        UserId = userId,
                        Title = "AI Assistant Chat",
                        Symptoms = initialSymptom,
                        ChatTranscript = fullTranscript,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Symptomchecks.Add(newSession);
                }
                
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to persist chat transcript to database.");
            }

            return reply;
        }

        private async Task<string> RunAgentLoop(int userId, object initialRequestBody)
        {
            var currentBody = JsonSerializer.Serialize(initialRequestBody, new JsonSerializerOptions { DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull });
            
            // Allow up to 3 tool call turns internally to resolve data fetching
            for (int turn = 0; turn < 3; turn++)
            {
                var content = new StringContent(currentBody, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("chat/completions", content);
                var responseString = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"Groq API Error: {responseString}");
                    return "Sorry, I am currently unable to process your request due to a technical error.";
                }

                using var doc = JsonDocument.Parse(responseString);
                var root = doc.RootElement;
                var messageNode = root.GetProperty("choices")[0].GetProperty("message");

                string replyContent = null;
                if (messageNode.TryGetProperty("content", out var contentProp) && contentProp.ValueKind == JsonValueKind.String)
                {
                    replyContent = contentProp.GetString();
                }

                if (messageNode.TryGetProperty("tool_calls", out var toolCalls) && toolCalls.ValueKind == JsonValueKind.Array)
                {
                    // Deserializing current body to append assistant message and tool responses
                    var bodyDict = JsonSerializer.Deserialize<Dictionary<string, object>>(currentBody);
                    var messagesList = JsonSerializer.Deserialize<List<object>>(bodyDict["messages"].ToString());
                    
                    messagesList.Add(messageNode);

                    foreach (var toolCall in toolCalls.EnumerateArray())
                    {
                        var toolCallId = toolCall.GetProperty("id").GetString();
                        var functionNode = toolCall.GetProperty("function");
                        var functionName = functionNode.GetProperty("name").GetString();
                        var functionArgsStr = functionNode.GetProperty("arguments").GetString();

                        string toolResult = await ExecuteToolAsync(userId, functionName, functionArgsStr);

                        messagesList.Add(new
                        {
                            role = "tool",
                            tool_call_id = toolCallId,
                            name = functionName,
                            content = toolResult
                        });
                    }

                    bodyDict["messages"] = messagesList;
                    currentBody = JsonSerializer.Serialize(bodyDict, new JsonSerializerOptions { DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull });
                }
                else
                {
                    // No more tool calls, return final response
                    return replyContent ?? "No response generated.";
                }
            }

            return "I apologize, but I needed to think for too long. Please try asking your question again.";
        }

        private async Task<string> ExecuteToolAsync(int userId, string functionName, string argumentsStr)
        {
            try
            {
                switch (functionName)
                {
                    case "analyze_and_find_doctors":
                        return await AnalyzeAndFindDoctorsAsync();
                    
                    case "get_active_prescriptions":
                        return await GetActivePrescriptionsAsync(userId);
                        
                    case "execute_final_booking":
                        using (var doc = JsonDocument.Parse(argumentsStr))
                        {
                            var args = doc.RootElement;
                            int doctorId = args.GetProperty("doctorId").GetInt32();
                            var dateStr = args.GetProperty("appointmentDate").GetString();
                            var timeStr = args.GetProperty("appointmentTime").GetString();
                            var reason = args.GetProperty("reason").GetString();

                            return await ExecuteFinalBookingAsync(userId, doctorId, dateStr, timeStr, reason);
                        }

                    case "setup_automated_reminder":
                        using (var doc = JsonDocument.Parse(argumentsStr))
                        {
                            var args = doc.RootElement;
                            var medicineName = args.GetProperty("medicineName").GetString();
                            var dosage = args.GetProperty("dosage").GetString();
                            var frequency = args.GetProperty("frequency").GetString();
                            var scheduledTimeStr = args.GetProperty("scheduledTime").GetString();

                            return await SetupAutomatedReminderAsync(userId, medicineName, dosage, frequency, scheduledTimeStr);
                        }

                    default:
                        return $"Error: Tool {functionName} not found.";
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error executing tool {functionName}");
                return $"Error executing tool: {ex.Message}";
            }
        }

        private async Task<string> AnalyzeAndFindDoctorsAsync()
        {
            var doctors = await _context.Doctors
                .Include(d => d.User)
                .Include(d => d.Doctorschedules)
                .Include(d => d.Doctorleaves)
                .Where(d => d.IsAvailable == true)
                .ToListAsync();

            var result = doctors.Select(d => new
            {
                DoctorId = d.Id,
                Name = d.User?.FullName,
                Specialization = d.Specialization,
                RoomNumber = d.RoomNumber,
                Schedules = d.Doctorschedules.Where(s => s.IsActive == true).Select(s => new { s.DayOfWeek, s.StartTime, s.EndTime }),
                ActiveLeaves = d.Doctorleaves.Where(l => l.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow)).Select(l => new { l.StartDate, l.EndDate })
            });

            return JsonSerializer.Serialize(result);
        }

        private async Task<string> GetActivePrescriptionsAsync(int userId)
        {
            var prescriptions = await _context.Prescriptions
                .Include(p => p.Prescriptionmedicines)
                .Include(p => p.Appointment)
                .Where(p => p.Appointment != null && p.Appointment.PatientId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .Take(5)
                .ToListAsync();

            var result = prescriptions.Select(p => new
            {
                PrescriptionId = p.Id,
                Date = p.CreatedAt,
                Diagnosis = p.Diagnosis,
                Notes = p.Notes,
                Medicines = p.Prescriptionmedicines.Select(m => new
                {
                    m.MedicineName,
                    m.Dosage,
                    m.Frequency,
                    m.Duration,
                    m.Instructions
                })
            });

            return JsonSerializer.Serialize(result);
        }

        private async Task<string> ExecuteFinalBookingAsync(int userId, int doctorId, string dateStr, string timeStr, string reason)
        {
            if (!DateOnly.TryParse(dateStr, out var appointmentDate))
                return "Error: Invalid date format. Use YYYY-MM-DD.";
            
            if (!TimeOnly.TryParse(timeStr, out var appointmentTime))
                return "Error: Invalid time format. Use HH:MM:SS.";

            var appointment = new Appointment
            {
                PatientId = userId,
                DoctorId = doctorId,
                AppointmentDate = appointmentDate,
                AppointmentTime = appointmentTime,
                Symptoms = reason,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            _context.Appointments.Add(appointment);
            
            var notification = new Notification
            {
                UserId = doctorId, // Notify the doctor
                Title = "New Appointment Request",
                Message = $"A new appointment request has been made for {appointmentDate} at {appointmentTime}.",
                Type = "Appointment",
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                RelatedEntityType = "Appointment"
            };

            _context.Notifications.Add(notification);
            
            await _context.SaveChangesAsync();

            return JsonSerializer.Serialize(new { Status = "Success", AppointmentId = appointment.Id, Message = "Appointment booked successfully." });
        }

        private async Task<string> SetupAutomatedReminderAsync(int userId, string medicineName, string dosage, string frequency, string scheduledTimeStr)
        {
            var reminder = new Medicinereminder
            {
                StudentId = userId,
                MedicineName = medicineName,
                Dosage = dosage,
                Frequency = frequency,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                Notes = "Automated reminder setup by AI.",
                Times = JsonSerializer.Serialize(new List<string> { scheduledTimeStr }) // Simplified
            };

            _context.Medicinereminders.Add(reminder);
            await _context.SaveChangesAsync();

            return JsonSerializer.Serialize(new { Status = "Success", ReminderId = reminder.Id, Message = "Reminder setup successfully." });
        }

        private List<object> GetTools()
        {
            return new List<object>
            {
                new
                {
                    type = "function",
                    function = new
                    {
                        name = "analyze_and_find_doctors",
                        description = "Fetch all active doctors, their specialties, schedules, and active leaves to find suitable matches for a patient.",
                        parameters = new
                        {
                            type = "object",
                            properties = new { }
                        }
                    }
                },
                new
                {
                    type = "function",
                    function = new
                    {
                        name = "get_active_prescriptions",
                        description = "Fetch the authenticated user's active prescriptions and medicines.",
                        parameters = new
                        {
                            type = "object",
                            properties = new { }
                        }
                    }
                },
                new
                {
                    type = "function",
                    function = new
                    {
                        name = "execute_final_booking",
                        description = "Book an appointment for the user with a specific doctor.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                doctorId = new { type = "integer", description = "The ID of the doctor to book with." },
                                appointmentDate = new { type = "string", description = "The date of the appointment in YYYY-MM-DD format." },
                                appointmentTime = new { type = "string", description = "The time of the appointment in HH:MM:SS format." },
                                reason = new { type = "string", description = "The symptoms or reason for the appointment." }
                            },
                            required = new[] { "doctorId", "appointmentDate", "appointmentTime", "reason" }
                        }
                    }
                },
                new
                {
                    type = "function",
                    function = new
                    {
                        name = "setup_automated_reminder",
                        description = "Setup an automated medicine reminder for the user.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                medicineName = new { type = "string", description = "Name of the medicine." },
                                dosage = new { type = "string", description = "Dosage instructions." },
                                frequency = new { type = "string", description = "Frequency (e.g. 'Twice', 'Once')." },
                                scheduledTime = new { type = "string", description = "The scheduled time in HH:MM:SS format." }
                            },
                            required = new[] { "medicineName", "dosage", "frequency", "scheduledTime" }
                        }
                    }
                }
            };
        }
    }
}
