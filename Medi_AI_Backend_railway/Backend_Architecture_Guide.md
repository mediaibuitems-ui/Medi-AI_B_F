# Medi-AI — Complete Backend Technical Reference

> **University:** BUITEMS Medical Center | **Project:** FYP 2025-2026 | **Version:** 1.0  
> **Stack:** ASP.NET Core 8 + EF Core 8 + MySQL (Railway) | **Source:** Read directly from codebase

---

## 0. What Is Medi-AI? (Non-Technical)

Medi-AI is a healthcare management system built for BUITEMS (Balochistan University of IT, Engineering and Management Sciences). It connects **four types of users** — Students, Faculty, Doctors, and Admins — through a mobile/web app (Flutter) talking to a secure backend server hosted on Railway cloud.

A student can open the app, type their symptoms, get an AI-powered preliminary assessment, book an appointment with a campus doctor, receive a digital prescription, and track their full medical history — all from their phone. Doctors manage their schedule, accept/decline appointments, and write prescriptions. Admins oversee the entire system through a powerful dashboard with charts and statistics.

---

## 1. Glossary

| Term | Plain-English Meaning |
|---|---|
| **ASP.NET Core** | Microsoft's web framework — the engine running the server |
| **EF Core** | A translator that converts C# code into MySQL database commands automatically |
| **Migration** | A version-control file that safely updates the database structure without losing data |
| **JWT** | A digital ID card (JSON Web Token) that proves a user is logged in |
| **Middleware** | A series of checkpoints every request passes through before reaching the actual code |
| **Controller** | A C# class that receives HTTP requests and returns responses |
| **DTO** | Data Transfer Object — a strict shape of what JSON data can be sent or received |
| **DbContext** | The master control panel connecting EF Core to the MySQL database |
| **Foreign Key** | A link in the database connecting one table to another |
| **Rate Limiter** | A bouncer that blocks users sending too many requests too fast |
| **CORS** | A browser security rule ensuring only approved websites can call the API |
| **Kestrel** | The built-in web server inside ASP.NET Core |
| **Railway** | The cloud hosting platform where the backend and database live |
| **Swagger** | An interactive web page at `/swagger` listing all API endpoints for testing |

---

## 2. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (Client)                                │
│  User taps → GetX Controller → Dio HTTP → _AuthInterceptor adds JWT    │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ HTTPS Request
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              ASP.NET Core 8 — Railway Cloud Server                      │
│                                                                         │
│  Kestrel receives packet                                                │
│       ↓                                                                 │
│  GlobalExceptionMiddleware (catches unhandled crashes)                  │
│       ↓                                                                 │
│  Static Files (profile photos)                                          │
│       ↓                                                                 │
│  CORS Policy "DefaultCors" (dev: any origin; prod: env variable list)   │
│       ↓                                                                 │
│  Rate Limiter (5 requests/min per IP on Auth endpoints)                 │
│       ↓                                                                 │
│  UseAuthentication() — JwtBearer validates token signature + expiry     │
│       ↓                                                                 │
│  JWT Revocation Middleware — checks IMemoryCache["Blacklist_{token}"]  │
│       ↓                                                                 │
│  UseAuthorization() — enforces [Authorize(Roles="...")] attributes      │
│       ↓                                                                 │
│  MapControllers() — routes URL to the correct Controller class          │
│       ↓                                                                 │
│  Controller Action — validates DTO, calls Service/DbContext             │
│       ↓                                                                 │
│  EF Core → MySQL — executes parameterized SQL query                     │
│       ↓                                                                 │
│  ApiResponse<T> JSON envelope returned to Flutter                       │
└─────────────────────────────────────────────────────────────────────────┘
```

**Standard JSON Response Envelope — every endpoint uses this shape:**
```json
{
  "success": true,
  "message": "Appointment booked successfully",
  "data": { ... }
}
```

---

## 3. Project File Structure

```
Medi_AI_Backend_railway/
└── Backend-APIs/
    ├── Controllers/              14 controller files — one per feature area
    ├── DTOs/                     25 DTO files — strict JSON input/output shapes
    ├── Models/                   25 model files — one per MySQL table + DbContext
    ├── Services/                 7 service files — business logic and external integrations
    ├── Middleware/               GlobalExceptionMiddleware.cs
    ├── Migrations/               6 migration files (schema history)
    ├── Program.cs                Entry point — all DI, middleware, DB connection
    ├── appsettings.json          Config skeleton (actual secrets in Railway env vars)
    └── Dockerfile                Railway container build instructions
```

### Why Each Layer Exists

| Layer | Why It Exists |
|---|---|
| **Controllers** | Handle HTTP routing only. No business logic inside. |
| **DTOs** | Prevent overposting. A client cannot send `{"Role":"Admin"}` to escalate privileges because the DTO does not have a `Role` field. |
| **Models** | Represent the exact MySQL table structure. Never returned directly to the client. |
| **Services** | Business logic lives here, not in Controllers. Makes testing possible without HTTP. |
| **Middleware** | Rules applied to every request (exceptions, revocation) without repeating code in every controller. |

---

## 4. Database Connection (Program.cs)

The connection string is built dynamically in `BuildMySqlConnectionString()`:

**Priority order:**
1. `MYSQL_URL` environment variable (Railway sets this automatically)
2. `DATABASE_URL` environment variable (fallback)
3. Individual env vars: `MYSQLHOST`, `MYSQLPORT`, `MYSQLDATABASE`, `MYSQLUSER`, `MYSQLPASSWORD`
4. `appsettings.json` → `ConnectionStrings:DefaultConnection` (local dev fallback)

**On startup:** `context.Database.Migrate()` runs inside a scoped service block — this automatically applies any pending migrations when the Railway container starts, so schema updates deploy without manual SQL.

---

## 5. Complete Database Schema (All 23 Tables)

All tables read directly from `Models/` files. Every column, type, and relationship documented below.

---

### Table: `Users`
*In plain terms: Every person in the system — students, faculty, doctors, admins.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key, auto-increment |
| `Email` | `string` | No | Unique. Students must use `@student.buitms.edu.pk` |
| `PasswordHash` | `string` | No | BCrypt hash — password never stored in plaintext |
| `FullName` | `string` | No | Display name |
| `Role` | `string` | No | `Student`, `Doctor`, `Faculty`, `Admin` |
| `Department` | `string?` | Yes | Academic department |
| `RegistrationNumber` | `string?` | Yes | Student/faculty ID |
| `PhoneNumber` | `string?` | Yes | |
| `DateOfBirth` | `DateOnly?` | Yes | |
| `Gender` | `string?` | Yes | |
| `Address` | `string?` | Yes | |
| `ProfileImageUrl` | `string?` | Yes | Path to uploaded photo |
| `IsEmailVerified` | `bool?` | Yes | Must be `true` before login is permitted |
| `IsActive` | `bool?` | Yes | `false` = account locked out by Admin |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |
| `LastLoginAt` | `DateTime?` | Yes | |

**Navigation (relationships):** → Doctor (1:1), → Appointments (1:N as patient), → Notifications (1:N), → AiSymptomAnalyses (1:N), → MedicalHistories (1:N), → MedicineReminders (1:N), → EmergencyContacts (1:N), → Feedbacks (1:N), → Reports (1:N), → RefreshTokens (1:N), → PasswordResetTokens (1:N), → EmailVerificationOtps (1:N), → Auditlogs (1:N)

**Used by:** `AuthController`, `UsersController`, `AdminController`

---

### Table: `Doctors`
*In plain terms: Extra medical profile for users who are doctors.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` — 1:1 relationship |
| `Specialization` | `string` | No | e.g., "General Physician" |
| `LicenseNumber` | `string` | No | Medical license number |
| `Qualification` | `string` | No | e.g., "MBBS" |
| `Experience` | `int?` | Yes | Years of experience |
| `RoomNumber` | `string?` | Yes | Campus clinic room |
| `Bio` | `string?` | Yes | Short description |
| `AverageRating` | `decimal?` | Yes | Computed from DoctorReviews |
| `TotalRatings` | `int?` | Yes | Count of ratings |
| `IsAvailable` | `bool?` | Yes | Is accepting appointments |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

**Navigation:** → Appointments (1:N), → DoctorLeaves (1:N), → DoctorReviews (1:N), → DoctorSchedules (1:N), → User (1:1)

**Used by:** `DoctorsController`, `AppointmentsController`, `AdminController`

---

### Table: `Appointments`
*In plain terms: The master ledger of every medical visit booking.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `PatientId` | `int` | No | FK → `Users.Id` |
| `DoctorId` | `int` | No | FK → `Doctors.Id` |
| `AppointmentDate` | `DateOnly` | No | Hospital-local date (no timezone) |
| `AppointmentTime` | `TimeOnly` | No | Hospital-local time (no timezone) |
| `Duration` | `int?` | Yes | Minutes |
| `Status` | `string?` | Yes | `Pending`, `Confirmed`, `Completed`, `Cancelled` |
| `Symptoms` | `string?` | Yes | Patient-described symptoms at booking |
| `Notes` | `string?` | Yes | Doctor notes |
| `CancellationReason` | `string?` | Yes | Why it was cancelled |
| `CancelledBy` | `int?` | Yes | FK → `Users.Id` — who cancelled |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |
| `RowVersion` | `byte[]?` | Yes | `[Timestamp]` — optimistic concurrency lock |

**Navigation:** → Prescriptions (1:N), → DoctorReview (1:1), → Patient (FK User), → Doctor (FK Doctor)

**Used by:** `AppointmentsController`, `AdminController`, `FacultyController`

---

### Table: `Doctorleaves` (mapped from `DoctorLeaf.cs`)
*In plain terms: Dates when a doctor is unavailable and cannot be booked.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `DoctorId` | `int` | No | FK → `Doctors.Id` |
| `StartDate` | `DateOnly` | No | Leave start (inclusive) |
| `EndDate` | `DateOnly` | No | Leave end (inclusive) |
| `Reason` | `string?` | Yes | Optional reason text |
| `CreatedAt` | `DateTime?` | Yes | |

**Used by:** `DoctorsController`, `AdminController`

---

### Table: `Doctorschedules`
*In plain terms: The recurring weekly working hours for each doctor.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `DoctorId` | `int` | No | FK → `Doctors.Id` |
| `DayOfWeek` | `string` | No | e.g., "Monday" |
| `StartTime` | `TimeOnly` | No | Shift start |
| `EndTime` | `TimeOnly` | No | Shift end |
| `IsActive` | `bool?` | Yes | Enable/disable specific day |
| `CreatedAt` | `DateTime?` | Yes | |

**Used by:** `DoctorsController`

---

### Table: `Prescriptions`
*In plain terms: The medical document written by a doctor after a completed appointment.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `AppointmentId` | `int` | No | FK → `Appointments.Id` |
| `Diagnosis` | `string` | No | Medical condition diagnosed |
| `Notes` | `string?` | Yes | General instructions |
| `FollowUpDate` | `DateOnly?` | Yes | Next suggested visit |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

**Navigation:** → PrescriptionMedicines (1:N), → Appointment (FK)

**Used by:** `PrescriptionsController`, `AppointmentsController`

---

### Table: `Prescriptionmedicines`
*In plain terms: The individual medicines listed inside a prescription.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `PrescriptionId` | `int` | No | FK → `Prescriptions.Id` |
| `MedicineName` | `string` | No | Drug name |
| `Dosage` | `string` | No | e.g., "500mg" |
| `Frequency` | `string` | No | e.g., "Twice daily" |
| `Duration` | `string` | No | e.g., "7 days" |
| `Instructions` | `string?` | Yes | e.g., "Take after food" |
| `CreatedAt` | `DateTime?` | Yes | |

**Used by:** `PrescriptionsController`

---

### Table: `Notifications`
*In plain terms: The alerts that appear in the user's notification bell icon.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` |
| `Title` | `string` | No | Short headline |
| `Message` | `string` | No | Full notification body |
| `Type` | `string` | No | e.g., `appointment`, `prescription` |
| `RelatedEntityId` | `int?` | Yes | ID of the linked appointment/prescription |
| `RelatedEntityType` | `string?` | Yes | e.g., `Appointment` |
| `IsRead` | `bool?` | Yes | Badge counter source |
| `ReadAt` | `DateTime?` | Yes | |
| `CreatedAt` | `DateTime?` | Yes | |

**Used by:** `NotificationsController`, `AppointmentsController` (inserts on status change)

---

### Table: `AiSymptomAnalysis`
*In plain terms: A log of every AI symptom check a user has run.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `Guid` | No | Primary Key (GUID) |
| `UserId` | `int` | No | FK → `Users.Id` |
| `SelectedSymptoms` | `string?` | Yes | JSON array of symptom strings |
| `OtherSymptoms` | `string?` | Yes | Free-text additional symptoms |
| `SeverityInput` | `string?` (max 50) | Yes | User-reported severity |
| `Duration` | `string?` (max 100) | Yes | e.g., "3 days" |
| `PossibleCondition` | `string?` | Yes | AI-predicted condition |
| `ConfidenceLevel` | `string?` (max 50) | Yes | e.g., "High", "Moderate" |
| `CalculatedSeverity` | `string?` (max 50) | Yes | AI-computed severity level |
| `UrgencyMessage` | `string?` | Yes | What the user should do next |
| `Recommendations` | `string?` | Yes | JSON array of action items |
| `HomeCareGuidance` | `string?` | Yes | JSON array of home care tips |
| `RecommendedDoctorType` | `string?` (max 100) | Yes | Specialist suggestion |
| `CreatedAt` | `DateTime` | No | UTC timestamp |

**Used by:** `SymptomAnalyzerController`

---

### Table: `Medicalhistories`
*In plain terms: A patient's ongoing medical record — allergies, chronic conditions, past diagnoses.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `PatientId` | `int` | No | FK → `Users.Id` |
| `RecordType` | `string` | No | e.g., "Allergy", "Chronic Condition" |
| `Title` | `string` | No | Name of condition |
| `Description` | `string?` | Yes | Details |
| `DiagnosisDate` | `DateOnly?` | Yes | When diagnosed |
| `Notes` | `string?` | Yes | Additional notes |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

**Used by:** `MedicalHistoryController`

---

### Table: `Medicinereminders`
*In plain terms: Scheduled alarms for patients to take their medicines.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `StudentId` | `int` | No | FK → `Users.Id` |
| `MedicineName` | `string` | No | |
| `Dosage` | `string` | No | e.g., "500mg" |
| `Frequency` | `string` | No | e.g., "Daily", "Weekly" |
| `CustomFrequency` | `string?` | Yes | Free-text custom schedule |
| `Times` | `string` | No | JSON array of time strings |
| `StartDate` | `DateOnly` | No | When to start reminders |
| `EndDate` | `DateOnly?` | Yes | When to stop |
| `Notes` | `string?` | Yes | |
| `IsActive` | `bool?` | Yes | |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

**Navigation:** → MedicineReminderLogs (1:N)

**Used by:** `MedicineRemindersController`

---

### Table: `Medicinereminderlogs`
*In plain terms: Tracks whether a patient actually took their medicine.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `ReminderId` | `int` | No | FK → `Medicinereminders.Id` |
| `ScheduledTime` | `DateTime` | No | When the dose was due |
| `TakenTime` | `DateTime?` | Yes | When they confirmed taking it |
| `Status` | `string?` | Yes | e.g., "Taken", "Missed" |
| `Notes` | `string?` | Yes | |
| `CreatedAt` | `DateTime?` | Yes | |

---

### Table: `Emergencycontacts`
*In plain terms: A user's emergency contact people (like a parent or spouse).*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` |
| `ContactName` | `string` | No | |
| `Relationship` | `string` | No | e.g., "Father", "Spouse" |
| `PhoneNumber` | `string` | No | |
| `Email` | `string?` | Yes | |
| `Address` | `string?` | Yes | |
| `IsPrimary` | `bool?` | Yes | |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

**Used by:** `EmergencyContactsController`

---

### Table: `Feedbacks`
*In plain terms: User-submitted feedback/complaints to the admin.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` |
| `Subject` | `string` | No | |
| `Message` | `string` | No | |
| `AdminResponse` | `string?` | Yes | Admin reply |
| `Status` | `string` | No | Default: "Pending" |
| `CreatedAt` | `DateTime` | No | |
| `RespondedAt` | `DateTime?` | Yes | |

**Used by:** `FeedbackController`

---

### Table: `Doctorreviews`
*In plain terms: Star ratings and reviews left by patients after appointments.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `DoctorId` | `int` | No | FK → `Doctors.Id` |
| `PatientId` | `int` | No | FK → `Users.Id` |
| `AppointmentId` | `int` | No | FK → `Appointments.Id` — 1:1 |
| `Rating` | `int` | No | 1–5 star rating |
| `Review` | `string?` | Yes | Optional text review |
| `IsAnonymous` | `bool?` | Yes | Hide patient identity |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

---

### Table: `Emailverificationotps`
*In plain terms: The 6-digit OTP codes sent during registration.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` |
| `Otp` | `string` | No | 6-digit code |
| `ExpiresAt` | `DateTime` | No | OTP validity window |
| `IsUsed` | `bool?` | Yes | Prevents replay attacks |
| `CreatedAt` | `DateTime?` | Yes | |

**Used by:** `AuthController`

---

### Table: `Passwordresettokens`
*In plain terms: The secure tokens sent in "Forgot Password" emails.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` |
| `Token` | `string` | No | Secure random token |
| `ExpiresAt` | `DateTime` | No | Token validity window |
| `IsUsed` | `bool?` | Yes | Single-use |
| `CreatedAt` | `DateTime?` | Yes | |

---

### Table: `Refreshtokens`
*In plain terms: Long-lived tokens used to get new JWT access tokens without re-logging in.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int` | No | FK → `Users.Id` |
| `Token` | `string` | No | Secure refresh token |
| `ExpiresAt` | `DateTime` | No | |
| `IsRevoked` | `bool?` | Yes | Revoked on logout |
| `ReplacedByToken` | `string?` | Yes | Token rotation chain |
| `CreatedAt` | `DateTime?` | Yes | |

---

### Table: `Auditlogs`
*In plain terms: A tamper-proof record of every important action in the system (who did what, when).*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `UserId` | `int?` | Yes | FK → `Users.Id` (null for system actions) |
| `Action` | `string` | No | e.g., "UserDeleted", "StatusChanged" |
| `EntityType` | `string?` | Yes | e.g., "Appointment" |
| `EntityId` | `int?` | Yes | ID of the affected record |
| `OldValues` | `string?` | Yes | JSON of previous values |
| `NewValues` | `string?` | Yes | JSON of new values |
| `IpAddress` | `string?` | Yes | Requestor's IP |
| `UserAgent` | `string?` | Yes | Browser/app string |
| `CreatedAt` | `DateTime?` | Yes | |

**Used by:** `AdminController`

---

### Table: `Systemsettings`
*In plain terms: Key-value configuration values editable by admins at runtime.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `SettingKey` | `string` | No | Unique setting name |
| `SettingValue` | `string` | No | Value (always stored as string) |
| `Description` | `string?` | Yes | What this setting controls |
| `DataType` | `string?` | Yes | e.g., "boolean", "integer" |
| `UpdatedBy` | `int?` | Yes | FK → `Users.Id` — who last changed it |
| `CreatedAt` | `DateTime?` | Yes | |
| `UpdatedAt` | `DateTime?` | Yes | |

---

### Table: `Reports`
*In plain terms: Generated reports (e.g., monthly appointment statistics) initiated by admins.*

| Column | Type | Nullable | Notes |
|---|---|---|---|
| `Id` | `int` | No | Primary Key |
| `ReportType` | `string` | No | e.g., "Monthly Summary" |
| `GeneratedBy` | `int` | No | FK → `Users.Id` |
| `StartDate` | `DateOnly` | No | Report date range start |
| `EndDate` | `DateOnly` | No | Report date range end |
| `Parameters` | `string?` | Yes | JSON extra filters |
| `FileUrl` | `string?` | Yes | Download link if generated |
| `Status` | `string?` | Yes | e.g., "Pending", "Completed" |
| `CreatedAt` | `DateTime?` | Yes | |
| `CompletedAt` | `DateTime?` | Yes | |

**Used by:** `ReportsController`

---

### Table: `Todaysappointment` ⚠️
*In plain terms: A pre-joined view of today's appointments for quick doctor display.*

| Column | Type | Notes |
|---|---|---|
| `AppointmentId` | `int` | Not a FK — this is a DB view projection |
| `AppointmentDate` | `DateOnly` | |
| `AppointmentTime` | `TimeOnly` | |
| `Status` | `string?` | |
| `PatientName` | `string` | Joined from Users |
| `PatientEmail` | `string` | Joined from Users |
| `DoctorId` | `int` | |
| `DoctorName` | `string` | Joined from Users via Doctors |
| `Specialization` | `string` | Joined from Doctors |

> ⚠️ **ORPHANED / VERIFY:** This model has no Primary Key and no active Controller endpoint writing to it. It appears to be a MySQL database VIEW projected into EF Core as a keyless entity. Verify its source SQL view before any migration changes.

---

### Table: `Activemedicinereminder` ⚠️
*Similar to Todaysappointment — likely a DB View. No active controller directly modifies it.*

---

### Table: `Doctorperformancesummary` ⚠️
*Likely a DB View aggregating rating statistics. No active controller directly modifies it.*

---

## 6. Database Relationship Map

```
Users ──────────────────────── 1:1 ──→ Doctors
Users ──────────────────────── 1:N ──→ Appointments          (as PatientId)
Users ──────────────────────── 1:N ──→ Notifications
Users ──────────────────────── 1:N ──→ AiSymptomAnalyses
Users ──────────────────────── 1:N ──→ MedicalHistories      (as PatientId)
Users ──────────────────────── 1:N ──→ MedicineReminders     (as StudentId)
Users ──────────────────────── 1:N ──→ EmergencyContacts
Users ──────────────────────── 1:N ──→ Feedbacks
Users ──────────────────────── 1:N ──→ RefreshTokens
Users ──────────────────────── 1:N ──→ PasswordResetTokens
Users ──────────────────────── 1:N ──→ EmailVerificationOtps
Users ──────────────────────── 1:N ──→ Auditlogs
Users ──────────────────────── 1:N ──→ Reports               (as GeneratedBy)
Users ──────────────────────── 1:N ──→ SystemSettings        (as UpdatedBy)

Doctors ────────────────────── 1:N ──→ Appointments
Doctors ────────────────────── 1:N ──→ DoctorLeaves
Doctors ────────────────────── 1:N ──→ DoctorSchedules
Doctors ────────────────────── 1:N ──→ DoctorReviews

Appointments ───────────────── 1:N ──→ Prescriptions
Appointments ───────────────── 1:1 ──→ DoctorReviews

Prescriptions ──────────────── 1:N ──→ PrescriptionMedicines

MedicineReminders ──────────── 1:N ──→ MedicineReminderLogs
```

---

## 7. NuGet Packages (from `Backend-APIs.csproj`)

| Package | Version | Role |
|---|---|---|
| `Pomelo.EntityFrameworkCore.MySql` | **8.0.2** | Core ORM — translates C# LINQ into optimized MySQL SQL |
| `Microsoft.EntityFrameworkCore.Design` | **8.0.11** | Enables `dotnet ef migrations add` CLI commands |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | **8.0.0** | Cryptographic JWT signature validation on every request |
| `BCrypt.Net-Next` | **4.0.3** | Password hashing with automatic salting (one-way, irreversible) |
| `MailKit` | **4.17.0** | SMTP email sending for OTPs and registration confirmations |
| `Swashbuckle.AspNetCore` | **6.5.0** | Auto-generates Swagger UI at `/swagger` in development mode |

---

## 8. All 14 Controllers & Their Endpoints

### `AuthController` — `/api/Auth`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/register` | None | Registers new user. Hashes password with BCrypt. Sends OTP via MailKit. |
| POST | `/send-otp` | None | Sends a 6-digit OTP to the email. |
| POST | `/verify-otp` | None | Validates OTP. Marks user as `IsEmailVerified = true`. |
| POST | `/login` | None | Validates credentials. Returns `accessToken` + `refreshToken`. |
| POST | `/refresh-token` | None | Exchanges refresh token for a new access token. |
| POST | `/logout` | JWT | Adds token to `IMemoryCache` blacklist. |
| POST | `/forgot-password` | None | Generates reset token. Sends via email. |
| POST | `/reset-password` | None | Validates reset token. Sets new BCrypt password. |

---

### `UsersController` — `/api/users`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/profile` | JWT | Returns profile from JWT `NameIdentifier` claim (not request body — spoof-proof). |
| PUT | `/profile` | JWT | Updates address, phone, etc. Cannot change Role. |
| POST | `/change-password` | JWT | Updates password using BCrypt. |
| POST | `/upload-photo` | JWT | Accepts multipart file. Saves URL in `ProfileImageUrl`. |

---

### `AppointmentsController` — `/api/Appointments`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/` | JWT | All appointments (admin view). |
| POST | `/` | JWT | Books appointment. Checks doctor availability + leave blocks. Status = `Pending`. Inserts `Notification`. |
| GET | `/my-appointments` | JWT | Appointments for logged-in user. |
| GET | `/student/{id}/history` | JWT | Student's past appointments. |
| GET | `/student/{id}/upcoming` | JWT | Student's upcoming appointments. |
| GET | `/Faculty/appointments` | JWT | Faculty-specific appointment list. |
| GET | `/{id}` | JWT | Single appointment detail. |
| PUT | `/{id}/status` | JWT | State machine: `Pending→Confirmed→Completed→Cancelled`. Triggers Notification insert. |
| PUT | `/{id}/prescription` | JWT | Doctor attaches prescription text to completed appointment. |
| PUT | `/{id}` | JWT | Edits appointment details. Uses `RowVersion` for optimistic concurrency. |
| DELETE | `/{id}` | JWT | Cancels appointment. Records `CancellationReason` and `CancelledBy`. |

---

### `DoctorsController` — `/api/doctors`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/` | JWT | Lists all `IsAvailable` doctors with specializations. |
| GET | `/{id}` | JWT | Single doctor profile. |
| POST | `/leaves` | JWT (Doctor) | Registers leave block. Validates against existing appointments. |
| GET | `/leaves` | JWT (Doctor) | Doctor's own leave history. |
| PUT | `/leaves/{id}` | JWT (Doctor) | Modifies leave dates. |
| DELETE | `/leaves/{id}` | JWT (Doctor) | Removes leave block. |

---

### `NotificationsController` — `/api/notifications`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/my-notifications` | JWT | All notifications for the logged-in user. |
| GET | `/unread-count` | JWT | Integer count for the badge icon. |
| PUT | `/{id}/read` | JWT | Marks one notification as read. Sets `ReadAt`. |
| PUT | `/mark-all-read` | JWT | Batch sets all user's notifications `IsRead = true`. |

---

### `AdminController` — `/api/admin`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/dashboard-stats` | JWT (Admin) | Aggregated totals: users, appointments, pending verifications. |
| GET | `/users` | JWT (Admin) | All users with filters/pagination. |
| POST | `/users` | JWT (Admin) | Creates a user manually. |
| PUT | `/users/{id}` | JWT (Admin) | Updates any user field. |
| DELETE | `/users/{id}` | JWT (Admin) | Removes a user. |
| PUT | `/verify-user/{id}` | JWT (Admin) | Sets `IsEmailVerified = true`. |
| GET | `/pending-verifications` | JWT (Admin) | Users waiting for verification. |
| GET | `/recent-activities` | JWT (Admin) | Audit log entries. |
| GET | `/recent-users` | JWT (Admin) | Newly registered users. |
| GET | `/notifications` | JWT (Admin) | System-wide notification log. |
| GET | `/doctor-leaves` | JWT (Admin) | All doctor leaves. |
| GET | `/system-settings` | JWT (Admin) | Reads `SystemSettings` table. |
| PUT | `/system-settings` | JWT (Admin) | Updates `SystemSettings` table. |
| POST | `/clear-cache` | JWT (Admin) | Purges `IMemoryCache`. |
| POST | `/backup-database` | JWT (Admin) | Triggers database backup mechanism. |

---

### `SymptomAnalyzerController` — `/api/analyzer`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/evaluate` | JWT | Receives symptoms JSON → Constructs system prompt → Calls Groq/Gemini API → Parses structured JSON → Inserts `AiSymptomAnalysis` row → Returns prediction to Flutter. **API key is in server env var — never exposed to client.** |

---

### `PrescriptionsController` — `/api/prescriptions`
Handles full CRUD for prescriptions and their medicine lists.

---

### `MedicalHistoryController` — `/api/medicalhistory`
CRUD for a patient's ongoing medical record entries.

---

### `MedicineRemindersController` — `/api/medicinereminders`
CRUD for patient medicine schedules. Flutter polls this to sync local notifications.

---

### `EmergencyContactsController` — `/api/emergencycontacts`
CRUD for user emergency contact records.

---

### `FeedbackController` — `/api/feedback`
Handles submission and admin responses to user feedback.

---

### `FacultyController` — `/api/faculty`
Faculty-specific endpoints (appointment views filtered for Faculty role).

---

### `ReportsController` — `/api/reports`
Admin-only report generation.

---

## 9. Backend Services

### `AuthService` (`IAuthService`) — `AuthService.cs`
Handles login logic, JWT generation, and password verification. Called by `AuthController`.

### `EmailService` (`IEmailService`) — `EmailService.cs`
Uses **MailKit** to send SMTP emails. Called for OTP emails, password reset emails, and registration confirmation.

### `UserService` (`IUserService`) — `UserService.cs`
Handles profile reads, profile updates, password changes, and photo uploads. Called exclusively by `UsersController`.

### `INotificationPushService`
Interface for push notification dispatch. Called when appointment status changes to alert the patient.

---

## 10. Security Configuration

### JWT Full Lifecycle
1. **Generation:** `AuthService` creates a signed JWT with claims: `NameIdentifier` (UserId), `Email`, `Role`, `Expiry`. Signed with `Jwt:Key` from environment variable.
2. **Storage (Flutter):** `FlutterSecureStorage` (AES-encrypted) on mobile, `SharedPreferences` on web.
3. **Attachment:** `_AuthInterceptor.onRequest()` adds `Authorization: Bearer <token>` to every Dio request.
4. **Validation:** `JwtBearer` middleware validates signature, audience, and expiry. Any mismatch → 401.
5. **Claim extraction:** Controllers use `User.FindFirst(ClaimTypes.NameIdentifier)` — **never from the JSON body** — making userId spoofing impossible.
6. **Revocation:** On logout, the token string is written to `IMemoryCache["Blacklist_{token}"]`. The inline middleware at step 4 in the pipeline checks this cache on every request.
7. **Refresh:** On 401, Flutter's `_AuthInterceptor` calls `POST /api/Auth/refresh-token`. Success → saves new tokens + retries request. Failure → clears local storage + navigates to login screen.

### CORS Configuration
- **Development:** `AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()` (local testing)
- **Production:** Origins loaded from `CORS_ALLOWED_ORIGINS` environment variable (semicolon-separated). Falls back to disallow-all if not configured.

### Rate Limiting
- Applied to Auth endpoints: **5 requests per minute per IP**
- Protects against brute-force password attacks

### No Payment Gateway (Deliberate Design Decision)
The system **intentionally has no Stripe, PayPal, or any commercial payment integration**. Appointment clearance is handled through:
- Internal state machine: `Pending → Confirmed → Completed`
- Direct hospital contact: `url_launcher` opens phone dialer
- Physical payment at BUITEMS Medical Center counter

This matches BUITEMS on-campus operational model and is not a missing feature.

---

## 11. Deployment Architecture

```
Developer machine
      │
      │ git push origin main
      ▼
GitHub Repository
      │
      │ Railway detects push
      ▼
Railway Build
  - Pulls Dockerfile from Medi_AI_Backend_railway/Backend-APIs/Dockerfile
  - Builds .NET 8 container
  - Restores NuGet packages (dotnet restore)
  - Publishes release build (dotnet publish)
      │
      ▼
Railway Container starts
  - Program.cs executes
  - Reads MYSQL_URL / MYSQLHOST env vars → builds connection string
  - context.Database.Migrate() → applies any new migrations
  - app.Run() → Kestrel listens on Railway-assigned port

Production URL: https://medi-aibf-production.up.railway.app
```

---

## 12. Known Issues & Gaps Found in Codebase

| # | Category | Finding | Risk |
|---|---|---|---|
| 1 | Database | `Todaysappointment`, `Activemedicinereminder`, `Doctorperformancesummary` are models with no PK — likely MySQL views projected as keyless EF entities | No active controller writes to them; verify SQL view definitions before migration cleanup |
| 2 | Migration | The `CleanupOrphanedTables` migration exists but its exact `Down()` method should be verified to ensure rollback is safe | Data loss on rollback if not reviewed |
| 3 | Frontend | `reports_screen.dart` and `system_settings_screen.dart` have no explicit `Binding` in `AppPages` | Controllers may not be properly disposed on navigation |
| 4 | Frontend | `ManageUsersScreen` loads all users without server-side pagination | Potential UI freeze on large user counts |
| 5 | Frontend | `FacultyDashboardController` — verify `StreamSubscription.cancel()` in `onClose()` | Memory leak risk |
| 6 | Security | `FailedLoginAttempts` and `LockoutEnd` fields exist as commented-out properties in `User.cs` | Account lockout feature is not yet implemented |

---

*Source files read: `Program.cs`, all 25 `Models/*.cs`, all 14 `Controllers/*.cs`, all 7 `Services/*.cs`, `Backend-APIs.csproj`, `Migrations/` directory listing.*
