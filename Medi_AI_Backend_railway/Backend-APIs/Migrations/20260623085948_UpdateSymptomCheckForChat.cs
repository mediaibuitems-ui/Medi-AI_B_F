using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend_APIs.Migrations
{
    /// <inheritdoc />
    public partial class UpdateSymptomCheckForChat : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Confidence",
                table: "symptomchecks");

            migrationBuilder.DropColumn(
                name: "Duration",
                table: "symptomchecks");

            migrationBuilder.DropColumn(
                name: "RecommendedAction",
                table: "symptomchecks");

            migrationBuilder.DropColumn(
                name: "Severity",
                table: "symptomchecks");

            migrationBuilder.RenameColumn(
                name: "AIResponse",
                table: "symptomchecks",
                newName: "ChatTranscript");

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "symptomchecks",
                type: "varchar(255)",
                maxLength: 255,
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Title",
                table: "symptomchecks");

            migrationBuilder.RenameColumn(
                name: "ChatTranscript",
                table: "symptomchecks",
                newName: "AIResponse");

            migrationBuilder.AddColumn<decimal>(
                name: "Confidence",
                table: "symptomchecks",
                type: "decimal(5,2)",
                precision: 5,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Duration",
                table: "symptomchecks",
                type: "varchar(50)",
                maxLength: 50,
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "RecommendedAction",
                table: "symptomchecks",
                type: "varchar(200)",
                maxLength: 200,
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "Severity",
                table: "symptomchecks",
                type: "enum('Mild','Moderate','Severe')",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");
        }
    }
}
