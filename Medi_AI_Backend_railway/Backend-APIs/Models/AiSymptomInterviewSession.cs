using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend_APIs.Models
{
    public class AiSymptomInterviewSession
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public int UserId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? CompletedAt { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "in_progress"; // "in_progress" | "completed" | "emergency_routed" | "abandoned"

        // Phase A checklist responses
        public string? RedFlagAnswers { get; set; } // Stored as JSON string

        public bool RedFlagTriggered { get; set; } = false;

        // The full Phase B Q&A history, in order
        // Stored as JSON array of { question: string, answer: string }
        public string? Transcript { get; set; } 

        // Populated only on completion
        // Schema in Section 4 of spec
        public string? FinalAnalysis { get; set; } // Stored as JSON string

        // Additional Context for Phase A (Optional but useful for LLM)
        public int? Age { get; set; }
        public string? BiologicalSex { get; set; }
        public string? PregnancyStatus { get; set; }
        public string? ExistingConditions { get; set; } 
        public string? CurrentMedications { get; set; }
        public string? Allergies { get; set; }

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
    }
}
