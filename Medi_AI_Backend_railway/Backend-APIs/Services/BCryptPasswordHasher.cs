using Backend_APIs.Models;
using Microsoft.AspNetCore.Identity;

namespace Backend_APIs.Services
{
    public class BCryptPasswordHasher : IPasswordHasher<User>
    {
        public string HashPassword(User user, string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password);
        }

        public PasswordVerificationResult VerifyHashedPassword(User user, string hashedPassword, string providedPassword)
        {
            try
            {
                if (BCrypt.Net.BCrypt.Verify(providedPassword, hashedPassword))
                {
                    return PasswordVerificationResult.Success;
                }
            }
            catch
            {
                return PasswordVerificationResult.Failed;
            }

            return PasswordVerificationResult.Failed;
        }
    }
}
