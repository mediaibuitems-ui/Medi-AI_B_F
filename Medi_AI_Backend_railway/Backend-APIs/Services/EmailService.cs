using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace Backend_APIs.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;
        private readonly string _senderEmail;
        private readonly string _senderName;
        private readonly string _password; // This will now store the SendGrid API Key

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            var emailSettings = _configuration.GetSection("EmailSettings");
            _senderEmail = emailSettings["SenderEmail"] ?? "mediaibuitems@gmail.com";
            _senderName = emailSettings["SenderName"] ?? "BUITEMS Medi-AI";
            _password = emailSettings["Password"] ?? "";

            Console.WriteLine($"[DEBUG] EmailService initialized for SendGrid API.");
            Console.WriteLine($"[DEBUG] SenderEmail: '{_senderEmail}'");
        }

        public async Task<bool> SendEmailAsync(string toEmail, string subject, string htmlBody)
        {
            try
            {
                if (string.IsNullOrEmpty(_password))
                {
                    _logger.LogWarning("Email credentials (API Key) not configured. Cannot send email to {ToEmail}", toEmail);
                    return false;
                }

                // Construct SendGrid JSON Payload
                var payload = new
                {
                    personalizations = new[]
                    {
                        new
                        {
                            to = new[] { new { email = toEmail } },
                            subject = subject
                        }
                    },
                    from = new
                    {
                        email = _senderEmail,
                        name = _senderName
                    },
                    content = new[]
                    {
                        new
                        {
                            type = "text/html",
                            value = htmlBody
                        }
                    }
                };

                var jsonContent = JsonSerializer.Serialize(payload);
                var httpContent = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                using var client = new HttpClient();
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _password);

                // Timeout after 10 seconds just in case
                client.Timeout = TimeSpan.FromSeconds(10);

                var response = await client.PostAsync("https://api.sendgrid.com/v3/mail/send", httpContent);

                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Email sent successfully via SendGrid to {ToEmail}", toEmail);
                    return true;
                }
                else
                {
                    var responseBody = await response.Content.ReadAsStringAsync();
                    _logger.LogError("SendGrid API returned {StatusCode}: {ResponseBody}", response.StatusCode, responseBody);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send HTTP email to {ToEmail}", toEmail);
                return false;
            }
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string userName, string otp)
        {
            var subject = "Email Verification - MediAI Healthcare";
            var htmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ text-align: center; color: #2563eb; margin-bottom: 30px; }}
        .otp-box {{ background-color: #eff6ff; border: 2px solid #2563eb; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }}
        .otp-code {{ font-size: 32px; font-weight: bold; color: #1e40af; letter-spacing: 5px; }}
        .content {{ color: #333; line-height: 1.6; }}
        .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center; color: #6b7280; font-size: 12px; }}
        .warning {{ color: #dc2626; font-size: 14px; margin-top: 15px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>?? MediAI Healthcare</h1>
        </div>
        <div class='content'>
            <h2>Hello {userName},</h2>
            <p>Thank you for registering with MediAI Healthcare! Please verify your email address using the OTP below:</p>
            
            <div class='otp-box'>
                <p style='margin: 0; font-size: 14px; color: #6b7280;'>Your Verification Code</p>
                <div class='otp-code'>{otp}</div>
                <p style='margin: 10px 0 0 0; font-size: 12px; color: #6b7280;'>Valid for 10 minutes</p>
            </div>
            
            <p>Enter this code in the verification page to complete your registration.</p>
            <p class='warning'>?? If you didn't request this code, please ignore this email.</p>
        </div>
        <div class='footer'>
            <p>� 2024 MediAI Healthcare. All rights reserved.</p>
            <p>This is an automated email. Please do not reply.</p>
        </div>
    </div>
</body>
</html>";

            return await SendEmailAsync(toEmail, subject, htmlBody);
        }

        public async Task<bool> SendWelcomeEmailAsync(string toEmail, string userName)
        {
            var subject = "Welcome to MediAI Healthcare! ??";
            var htmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ text-align: center; color: #2563eb; margin-bottom: 30px; }}
        .content {{ color: #333; line-height: 1.6; }}
        .button {{ display: inline-block; background-color: #2563eb; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
        .features {{ background-color: #f9fafb; padding: 20px; border-radius: 8px; margin: 20px 0; }}
        .feature-item {{ margin: 10px 0; }}
        .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center; color: #6b7280; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>?? Welcome to MediAI Healthcare!</h1>
        </div>
        <div class='content'>
            <h2>Hello {userName},</h2>
            <p>Your email has been verified successfully! Welcome to our healthcare community.</p>
            
            <div class='features'>
                <h3>What you can do now:</h3>
                <div class='feature-item'>? Book appointments with doctors</div>
                <div class='feature-item'>?? Set up medicine reminders</div>
                <div class='feature-item'>?? Track your health records</div>
                <div class='feature-item'>????? Connect with healthcare professionals</div>
                <div class='feature-item'>?? Receive important health notifications</div>
            </div>
            
            <p>If you have any questions or need assistance, feel free to reach out to our support team.</p>
            <p><strong>Stay healthy! ??</strong></p>
        </div>
        <div class='footer'>
            <p>� 2024 MediAI Healthcare. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";

            return await SendEmailAsync(toEmail, subject, htmlBody);
        }

        public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string userName, string resetToken)
        {
            var subject = "Password Reset Request - MediAI Healthcare";
            var htmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ text-align: center; color: #2563eb; margin-bottom: 30px; }}
        .content {{ color: #333; line-height: 1.6; }}
        .token-box {{ background-color: #fef2f2; border: 2px solid #dc2626; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }}
        .token {{ font-family: monospace; font-size: 14px; color: #991b1b; word-break: break-all; }}
        .warning {{ color: #dc2626; font-size: 14px; margin-top: 15px; }}
        .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; text-align: center; color: #6b7280; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>?? MediAI Healthcare</h1>
        </div>
        <div class='content'>
            <h2>Hello {userName},</h2>
            <p>We received a request to reset your password. Use the token below to reset your password:</p>
            
            <div class='token-box'>
                <p style='margin: 0; font-size: 14px; color: #6b7280;'>Reset Token</p>
                <div class='token'>{resetToken}</div>
                <p style='margin: 10px 0 0 0; font-size: 12px; color: #6b7280;'>Valid for 1 hour</p>
            </div>
            
            <p class='warning'>?? If you didn't request a password reset, please ignore this email and ensure your account is secure.</p>
        </div>
        <div class='footer'>
            <p>� 2024 MediAI Healthcare. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";

            return await SendEmailAsync(toEmail, subject, htmlBody);
        }
    }
}
