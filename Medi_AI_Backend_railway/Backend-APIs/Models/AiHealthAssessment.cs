using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend_APIs.Models
{
    public class AiHealthAssessment
    {
        [Key]
        public Guid AssessmentId { get; set; } = Guid.NewGuid();

        [Required]
        public int UserId { get; set; }

        [Required]
        public string RawSymptoms { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string TriageLevel { get; set; } = null!;

        [Required]
        public string ClinicalAnalysis { get; set; } = null!;

        public string? SuggestedMedicine { get; set; }

        public string? HomeCarePlan { get; set; } // Stored as JSON string

        [MaxLength(100)]
        public string? RecommendedDoctor { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
    }
}
