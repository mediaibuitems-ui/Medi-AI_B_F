using System;

namespace Backend_APIs.Models
{
    public partial class RevokedToken
    {
        public int Id { get; set; }
        
        /// <summary>
        /// A SHA-256 hash of the revoked access token
        /// </summary>
        public string TokenHash { get; set; } = null!;
        
        public DateTime ExpiresAt { get; set; }
        
        public DateTime CreatedAt { get; set; }
    }
}
