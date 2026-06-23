using System.Collections.Generic;

namespace Backend_APIs.DTOs
{
    public class AgentChatMessage
    {
        public string Role { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }

    public class AgentChatRequestDto
    {
        public List<AgentChatMessage> Messages { get; set; } = new List<AgentChatMessage>();
    }

    public class AgentChatResponseDto
    {
        public string Reply { get; set; } = string.Empty;
    }
}
