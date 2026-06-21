namespace Backend_APIs.Services
{
    public interface INotificationPushService
    {
        Task PushNotificationAsync(int userId, string title, string message, string type, string? relatedEntityType = null);
    }

    public class NotificationPushService : INotificationPushService
    {
        private readonly ILogger<NotificationPushService> _logger;

        public NotificationPushService(ILogger<NotificationPushService> logger)
        {
            _logger = logger;
        }

        public Task PushNotificationAsync(int userId, string title, string message, string type, string? relatedEntityType = null)
        {
            // TODO: In the future, implement SignalR or Firebase Cloud Messaging (FCM) here
            // Example: _hubContext.Clients.User(userId.ToString()).SendAsync("ReceiveNotification", new { title, message, type });

            _logger.LogInformation($"[PUSH NOTIFICATION STUB] To User {userId}: {title} - {message} (Type: {type})");
            return Task.CompletedTask;
        }
    }
}
