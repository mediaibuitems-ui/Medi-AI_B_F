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

        public int? Age { get; set; }
        public string? BiologicalSex { get; set; }
        public string? Onset { get; set; }
        public bool RedFlagsTriggered { get; set; } = false;
        public string? RedFlagsDetail { get; set; } // JSON or comma-separated string
        public string? ExistingConditions { get; set; } // JSON or text
        public string? CurrentMedications { get; set; }
        public string? Allergies { get; set; }
        public string? PregnancyStatus { get; set; }

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

        public string? TriageTier { get; set; }
        public string? WhenToSeekCare { get; set; }
        public string Status { get; set; } = "analyzed";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
    }
}
