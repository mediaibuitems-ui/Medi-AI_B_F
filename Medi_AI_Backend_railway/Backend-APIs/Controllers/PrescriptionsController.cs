using Backend_APIs.DTOs;
using Backend_APIs.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend_APIs.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class PrescriptionsController : ControllerBase
    {
        private readonly MediaidbContext _context;

        public PrescriptionsController(MediaidbContext context)
        {
            _context = context;
        }

        [HttpGet("my-prescriptions")]
        public async Task<IActionResult> GetMyPrescriptions()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null) return Unauthorized(new ApiResponse<object> { Success = false, Message = "Invalid token" });
                var userId = int.Parse(userIdClaim.Value);

                var prescriptions = await _context.Prescriptions
                    .Include(p => p.Appointment)
                        .ThenInclude(a => a.Doctor)
                            .ThenInclude(d => d.User)
                    .Include(p => p.Prescriptionmedicines)
                    .Where(p => p.Appointment.PatientId == userId)
                    .OrderByDescending(p => p.CreatedAt)
                    .Select(p => new
                    {
                        p.Id,
                        AppointmentId = p.AppointmentId,
                        DoctorName = p.Appointment.Doctor.User.FullName,
                        AppointmentDate = p.Appointment.AppointmentDate,
                        Diagnosis = p.Diagnosis,
                        Notes = p.Notes,
                        CreatedAt = p.CreatedAt,
                        Medicines = p.Prescriptionmedicines.Select(pm => new
                        {
                            pm.MedicineName,
                            pm.Dosage,
                            pm.Frequency,
                            pm.Duration,
                            pm.Instructions
                        })
                    })
                    .ToListAsync();

                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "Prescriptions retrieved successfully",
                    Data = prescriptions
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Failed to retrieve prescriptions: {ex.Message}"
                });
            }
        }

        [HttpPost]
        [Authorize(Roles = "Doctor,Admin")]
        public async Task<IActionResult> CreatePrescription([FromBody] CreatePrescriptionDto dto)
        {
            try
            {
                var appointment = await _context.Appointments.FindAsync(dto.AppointmentId);
                if (appointment == null) return NotFound(new ApiResponse<object> { Success = false, Message = "Appointment not found" });

                var prescription = new Prescription
                {
                    AppointmentId = dto.AppointmentId,
                    Diagnosis = dto.Diagnosis ?? string.Empty,
                    Notes = dto.Notes,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Prescriptions.Add(prescription);
                await _context.SaveChangesAsync();

                if (dto.Medicines != null && dto.Medicines.Any())
                {
                    foreach (var med in dto.Medicines)
                    {
                        _context.Prescriptionmedicines.Add(new Prescriptionmedicine
                        {
                            PrescriptionId = prescription.Id,
                            MedicineName = med.MedicineName ?? string.Empty,
                            Dosage = med.Dosage ?? string.Empty,
                            Frequency = med.Frequency ?? string.Empty,
                            Duration = med.Duration ?? string.Empty,
                            Instructions = med.Instructions,
                            CreatedAt = DateTime.UtcNow
                        });
                    }
                    await _context.SaveChangesAsync();
                }

                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "Prescription created successfully",
                    Data = new { PrescriptionId = prescription.Id }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Failed to create prescription: {ex.Message}"
                });
            }
        }
    }

    public class CreatePrescriptionDto
    {
        public int AppointmentId { get; set; }
        public string? Diagnosis { get; set; }
        public string? Notes { get; set; }
        public List<CreatePrescriptionMedicineDto>? Medicines { get; set; }
    }

    public class CreatePrescriptionMedicineDto
    {
        public string MedicineName { get; set; } = null!;
        public string? Dosage { get; set; }
        public string? Frequency { get; set; }
        public string? Duration { get; set; }
        public string? Instructions { get; set; }
    }
}
