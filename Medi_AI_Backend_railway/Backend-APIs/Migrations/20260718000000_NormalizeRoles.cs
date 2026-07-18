using Backend_APIs.Constants;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend_APIs.Migrations
{
    /// <inheritdoc />
    public partial class NormalizeRoles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("UPDATE users SET Role = 'Student' WHERE LOWER(Role) = 'student';");
            migrationBuilder.Sql("UPDATE users SET Role = 'Faculty' WHERE LOWER(Role) = 'faculty';");
            migrationBuilder.Sql("UPDATE users SET Role = 'Doctor' WHERE LOWER(Role) = 'doctor';");
            migrationBuilder.Sql("UPDATE users SET Role = 'Admin' WHERE LOWER(Role) = 'admin';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Roles normalized, no revert needed
        }
    }
}
