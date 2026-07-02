using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend_APIs.Models
{
    public class AiSymptomAnalysis
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public int UserId { get; set; }

        public string? SelectedSymptoms { get; set; }
        
        public string? OtherSymptoms { get; set; }

        [MaxLength(50)]
        public string? SeverityInput { get; set; }

        [MaxLength(100)]
        public string? Duration { get; set; }

        public string? PossibleCondition { get; set; }
        
        [MaxLength(50)]
        public string? ConfidenceLevel { get; set; }
        
        [MaxLength(50)]
        public string? CalculatedSeverity { get; set; }
        
        public string? UrgencyMessage { get; set; }

        public string? Recommendations { get; set; } // Stored as JSON string

        public string? HomeCareGuidance { get; set; } // Stored as JSON string

        [MaxLength(100)]
        public string? RecommendedDoctorType { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
    }
}
