using Backend_APIs.DTOs;
using Backend_APIs.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace Backend_APIs.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin,admin")]
    public class ReportsController : ControllerBase
    {
        private readonly MediaidbContext _context;

        public ReportsController(MediaidbContext context)
        {
            _context = context;
        }

        [HttpGet("appointments-trend")]
        public async Task<IActionResult> GetAppointmentsTrend([FromQuery] int days = 7)
        {
            try
            {
                var startDate = DateOnly.FromDateTime(DateTime.Today.AddDays(-days));

                var appointments = await _context.Appointments
                    .Where(a => a.AppointmentDate >= startDate)
                    .GroupBy(a => a.AppointmentDate)
                    .Select(g => new
                    {
                        Date = g.Key,
                        Count = g.Count()
                    })
                    .OrderBy(x => x.Date)
                    .ToListAsync();

                // Fill missing days with 0
                var trendData = new List<object>();
                for (int i = 0; i <= days; i++)
                {
                    var date = startDate.AddDays(i);
                    var record = appointments.FirstOrDefault(a => a.Date == date);
                    trendData.Add(new
                    {
                        Date = date.ToString("yyyy-MM-dd"),
                        Count = record?.Count ?? 0
                    });
                }

                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "Appointment trend data retrieved",
                    Data = trendData
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Failed to get trend data: {ex.Message}"
                });
            }
        }

        [HttpGet("users-distribution")]
        public async Task<IActionResult> GetUsersDistribution()
        {
            try
            {
                var distribution = await _context.Users
                    .GroupBy(u => u.Role)
                    .Select(g => new
                    {
                        Role = g.Key,
                        Count = g.Count()
                    })
                    .ToListAsync();

                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Message = "User distribution retrieved",
                    Data = distribution
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Failed to get distribution data: {ex.Message}"
                });
            }
        }
    }
}
