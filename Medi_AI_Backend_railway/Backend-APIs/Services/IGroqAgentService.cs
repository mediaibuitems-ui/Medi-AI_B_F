using Backend_APIs.DTOs;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend_APIs.Services
{
    public interface IGroqAgentService
    {
        Task<string> ExecuteAgentAsync(int userId, List<AgentChatMessage> conversationHistory);
    }
}
