using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend_APIs.Migrations
{
    /// <inheritdoc />
    public partial class UpdateAiSymptomAnalysis : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Age",
                table: "ai_symptom_analyses",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Allergies",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "BiologicalSex",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "CurrentMedications",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "ExistingConditions",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "Onset",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "PregnancyStatus",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "RedFlagsDetail",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<bool>(
                name: "RedFlagsTriggered",
                table: "ai_symptom_analyses",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: false,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "TriageTier",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "WhenToSeekCare",
                table: "ai_symptom_analyses",
                type: "longtext",
                nullable: true,
                collation: "utf8mb4_unicode_ci")
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "idx_user_created_active",
                table: "users",
                columns: new[] { "CreatedAt", "IsActive" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "idx_user_created_active",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Age",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "Allergies",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "BiologicalSex",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "CurrentMedications",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "ExistingConditions",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "Onset",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "PregnancyStatus",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "RedFlagsDetail",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "RedFlagsTriggered",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "TriageTier",
                table: "ai_symptom_analyses");

            migrationBuilder.DropColumn(
                name: "WhenToSeekCare",
                table: "ai_symptom_analyses");
        }
    }
}
