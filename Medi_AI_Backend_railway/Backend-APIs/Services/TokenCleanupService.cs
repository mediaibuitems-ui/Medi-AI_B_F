using Backend_APIs.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend_APIs.Services
{
    public class TokenCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<TokenCleanupService> _logger;

        public TokenCleanupService(IServiceProvider serviceProvider, ILogger<TokenCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var context = scope.ServiceProvider.GetRequiredService<MediaidbContext>();
                        
                        // Delete tokens that expired more than 30 days ago to keep the table clean
                        var cutoffDate = DateTime.UtcNow.AddDays(-30);
                        
                        var deletedCount = await context.RevokedTokens
                            .Where(t => t.ExpiresAt < cutoffDate)
                            .ExecuteDeleteAsync(stoppingToken);

                        if (deletedCount > 0)
                        {
                            _logger.LogInformation($"Cleaned up {deletedCount} expired revoked tokens.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "An error occurred while cleaning up revoked tokens.");
                }

                // Run once a day
                await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
            }
        }
    }
}
