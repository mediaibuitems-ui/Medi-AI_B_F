using Backend_APIs.DTOs;
using Backend_APIs.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Threading.Tasks;

namespace Backend_APIs.Controllers
{
    [Route("api/agent")]
    [ApiController]
    [Authorize]
    public class AgentController : ControllerBase
    {
        private readonly IGroqAgentService _groqAgentService;
        private readonly ILogger<AgentController> _logger;

        public AgentController(IGroqAgentService groqAgentService, ILogger<AgentController> logger)
        {
            _groqAgentService = groqAgentService;
            _logger = logger;
        }

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] AgentChatRequestDto request)
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
                {
                    return Unauthorized(new ApiResponse<object> { Success = false, Message = "Invalid or missing token" });
                }

                if (request.Messages == null || request.Messages.Count == 0)
                {
                    return BadRequest(new ApiResponse<object> { Success = false, Message = "Messages list cannot be empty." });
                }

                var reply = await _groqAgentService.ExecuteAgentAsync(userId, request.Messages);

                return Ok(new ApiResponse<AgentChatResponseDto>
                {
                    Success = true,
                    Message = "Agent responded successfully",
                    Data = new AgentChatResponseDto { Reply = reply }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing agent chat request");
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Agent error: {ex.Message}"
                });
            }
        }
    }
}
