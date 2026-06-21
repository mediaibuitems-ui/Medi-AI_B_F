using Backend_APIs.DTOs;
using Backend_APIs.Models;
using Backend_APIs.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace Backend_APIs.Controllers
{
    [Route("api/ai")]
    [ApiController]
    [Authorize]
    public class AiController : ControllerBase
    {
        private readonly IGeminiAiService _geminiAiService;
        private readonly MediaidbContext _context;

        public AiController(IGeminiAiService geminiAiService, MediaidbContext context)
        {
            _geminiAiService = geminiAiService;
            _context = context;
        }

        [HttpPost("analyze")]
        public async Task<IActionResult> Analyze([FromBody] AiAnalyzeRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null)
                {
                    return Unauthorized(new ApiResponse<object> { Success = false, Message = "Invalid token" });
                }

                var userId = int.Parse(userIdClaim.Value);
                var result = await _geminiAiService.AnalyzeAsync(request, cancellationToken);

                var symptoms = new List<string>(request.SelectedSymptoms ?? new List<string>());
                if (!string.IsNullOrWhiteSpace(request.AdditionalDescription))
                {
                    symptoms.Add(request.AdditionalDescription.Trim());
                }

                var record = new Symptomcheck
                {
                    UserId = userId,
                    Symptoms = JsonSerializer.Serialize(symptoms),
                    Duration = request.Duration ?? "Unknown",
                    Severity = result.Severity,
                    Airesponse = JsonSerializer.Serialize(new
                    {
                        result.Condition,
                        result.Answer
                    }),
                    Confidence = (decimal?)result.Confidence,
                    RecommendedAction = JsonSerializer.Serialize(new
                    {
                        result.Recommendations,
                        result.WarningSigns
                    }),
                    CreatedAt = DateTime.UtcNow
                };

                _context.Symptomchecks.Add(record);
                await _context.SaveChangesAsync(cancellationToken);

                return Ok(new ApiResponse<AiAnalyzeResultDto>
                {
                    Success = true,
                    Message = "AI analysis complete",
                    Data = result
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"AI analysis failed: {ex.Message}",
                    Data = null
                });
            }
        }

        [HttpGet("history")]
        public async Task<ActionResult<IEnumerable<SymptomCheckResponseDto>>> GetHistory()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!int.TryParse(userIdClaim, out var userId))
                {
                    return Unauthorized(new ApiResponse<object>
                    {
                        Success = false,
                        Message = "Invalid token",
                        Data = null,
                        Errors = null
                    });
                }

                var history = await _context.Symptomchecks
                    .Where(s => s.UserId == userId)
                    .OrderByDescending(s => s.CreatedAt)
                    .ToListAsync();

                var response = history.Select(h =>
                {
                    var actions = ParseActions(h.RecommendedAction);
                    var condition = ParseCondition(h.Airesponse);
                    return new SymptomCheckResponseDto
                    {
                        Id = h.Id,
                        Symptoms = h.Symptoms,
                        Condition = condition,
                        Confidence = h.Confidence ?? 0,
                        Severity = h.Severity ?? "Unknown",
                        Recommendations = actions.Recommendations,
                        WarningSigns = actions.Warnings,
                        CreatedAt = h.CreatedAt ?? DateTime.UtcNow
                    };
                });

                return Ok(new ApiResponse<IEnumerable<SymptomCheckResponseDto>>
                {
                    Success = true,
                    Message = "History retrieved",
                    Data = response
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Failed to load history: {ex.Message}"
                });
            }
        }

        private (List<string> Recommendations, List<string> Warnings) ParseActions(string? json)
        {
            if (string.IsNullOrEmpty(json))
            {
                return (new List<string>(), new List<string>());
            }

            try
            {
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;

                var recs = new List<string>();
                if (root.TryGetProperty("Recommendations", out var recProp))
                {
                    foreach (var item in recProp.EnumerateArray())
                    {
                        recs.Add(item.GetString() ?? string.Empty);
                    }
                }

                var warns = new List<string>();
                if (root.TryGetProperty("Warnings", out var warnProp))
                {
                    foreach (var item in warnProp.EnumerateArray())
                    {
                        warns.Add(item.GetString() ?? string.Empty);
                    }
                }

                return (recs, warns);
            }
            catch
            {
                return (new List<string> { json }, new List<string>());
            }
        }

        private static string ParseCondition(string? json)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return "Unknown";
            }

            try
            {
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;

                if (root.TryGetProperty("Condition", out var conditionProp))
                {
                    return conditionProp.GetString() ?? "Unknown";
                }
            }
            catch
            {
            }

            return json;
        }
    }
}
