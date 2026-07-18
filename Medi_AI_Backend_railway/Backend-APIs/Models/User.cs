using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace Backend_APIs.Models;

public partial class User : IdentityUser<int>
{
    // Id, Email, PasswordHash, PhoneNumber are inherited from IdentityUser<int>

    public string FullName { get; set; } = null!;

    public string Role { get; set; } = null!;

    public string? Department { get; set; }

    public string? RegistrationNumber { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    public string? Gender { get; set; }

    public string? Address { get; set; }

    public string? ProfileImageUrl { get; set; }

    public bool? IsEmailVerified { get; set; }


    public bool? IsActive { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public DateTime? LastLoginAt { get; set; }

    // public int FailedLoginAttempts { get; set; }

    // public DateTime? LockoutEnd { get; set; }

    public virtual ICollection<Appointment> AppointmentCancelledByNavigations { get; set; } = new List<Appointment>();

    public virtual ICollection<Appointment> AppointmentPatients { get; set; } = new List<Appointment>();

    public virtual ICollection<Auditlog> Auditlogs { get; set; } = new List<Auditlog>();

    public virtual Doctor? Doctor { get; set; }

    public virtual ICollection<Doctorreview> Doctorreviews { get; set; } = new List<Doctorreview>();

    public virtual ICollection<Emailverificationotp> Emailverificationotps { get; set; } = new List<Emailverificationotp>();

    public virtual ICollection<Emergencycontact> Emergencycontacts { get; set; } = new List<Emergencycontact>();

    public virtual ICollection<Medicalhistory> Medicalhistories { get; set; } = new List<Medicalhistory>();

    public virtual ICollection<Medicinereminder> Medicinereminders { get; set; } = new List<Medicinereminder>();

    public virtual ICollection<Feedback> Feedbacks { get; set; } = new List<Feedback>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Passwordresettoken> Passwordresettokens { get; set; } = new List<Passwordresettoken>();

    public virtual ICollection<Refreshtoken> RefreshTokens { get; set; } = new List<Refreshtoken>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ICollection<AiSymptomAnalysis> AiSymptomAnalyses { get; set; } = new List<AiSymptomAnalysis>();

    public virtual ICollection<Systemsetting> Systemsettings { get; set; } = new List<Systemsetting>();

}
