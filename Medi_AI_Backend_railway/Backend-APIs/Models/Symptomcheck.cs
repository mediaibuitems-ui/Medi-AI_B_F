using System;
using System.Collections.Generic;

namespace Backend_APIs.Models;

public partial class Symptomcheck
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string Symptoms { get; set; } = null!;

    public string? Title { get; set; }

    public string? ChatTranscript { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual User User { get; set; } = null!;
}
