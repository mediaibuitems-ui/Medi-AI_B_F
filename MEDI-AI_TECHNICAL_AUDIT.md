# MEDI-AI TECHNICAL AUDIT

> **Document Purpose:** Fact-check the Medi-AI thesis against the actual codebase.  
> **Audit Date:** 2026-07-28  
> **Auditor:** Antigravity (evidence-based, code-verified)  
> **Ground Truth Rule:** Every claim below cites an exact file path and line number. Claims that cannot be verified from code are marked **NOT FOUND / UNVERIFIABLE**.

---

## TASK 1 — Repository & File Architecture

### 1.1 Root Directory Structure

```
Medi-AI_F-B-main/                         <- Project root (Flutter frontend)
├── pubspec.yaml                           <- Flutter dependency manifest (v1.0.0+1)
├── lib/                                   <- All application Dart source code
│   ├── main.dart                          <- App entry point; initialises GetX services
│   ├── config/
│   │   └── app_config.dart               <- Base URLs, timeouts, JWT key names, allowed email domain
│   └── app/
│       ├── data/models/                  <- Dart model classes (appointment, doctor, user, etc.)
│       ├── modules/                      <- Feature modules (admin, auth, doctor, faculty, student)
│       ├── routes/                       <- GetX named route definitions
│       ├── services/                     <- Client-side services (API, Auth, Storage, Notifications)
│       └── widgets/                      <- Shared UI components
├── android/                              <- Android platform project
├── assets/                               <- Images, animations, icons
└── Medi_AI_Backend_railway/              <- Backend (ASP.NET Core 8.0)
    └── Backend-APIs/
        ├── Program.cs                    <- Entry point & DI container setup
        ├── appsettings.json              <- Local dev config (placeholder secrets)
        ├── Dockerfile                    <- Docker build instructions for Railway
        ├── Controllers/                  <- 13 API controllers
        ├── Models/                       <- 25 Entity Framework model classes + DbContext
        ├── Services/                     <- Business logic service layer
        ├── DTOs/                         <- Data Transfer Objects
        ├── Middleware/                   <- GlobalExceptionMiddleware
        └── Migrations/                   <- EF Core migration history
```

### 1.2 Entry Points & Configuration Files

| File | Role |
|---|---|
| `lib/main.dart` | Flutter app entry point |
| `lib/config/app_config.dart` | All client-side config (base URL, timeouts, storage keys) |
| `pubspec.yaml` | Flutter dependencies |
| `Medi_AI_Backend_railway/Backend-APIs/Program.cs` | ASP.NET Core DI, middleware pipeline |
| `Medi_AI_Backend_railway/Backend-APIs/appsettings.json` | Local dev config (secrets are placeholders) |
| `Medi_AI_Backend_railway/Backend-APIs/Dockerfile` | Docker container for Railway deployment |

### 1.3 Hosting / Deployment — DEFINITIVE FINDING

> **VERDICT: Railway. Not SmarterASP.net.**

**Evidence:**

1. **`Dockerfile`** (`Medi_AI_Backend_railway/Backend-APIs/Dockerfile`, lines 1-21): Docker multi-stage build, exposing port `8080`, setting `ASPNETCORE_URLS=http://+:8080`. This is a Railway-native deployment pattern.

2. **`lib/config/app_config.dart` (line 17-18):**
   Production base URL is hardcoded to `https://medi-aibf-production-54bc.up.railway.app/api` — a `*.up.railway.app` domain.

3. **`Program.cs` (lines 330-356):** Connection string builder reads Railway env vars: `MYSQL_URL`, `DATABASE_URL`, `MYSQLHOST`, `MYSQLPORT`, `MYSQLDATABASE`, `MYSQLUSER`, `MYSQLPASSWORD`.

4. **`appsettings.json` (line 23):** Comment says `INSERT_EMAIL_APP_PASSWORD_IN_RAILWAY`, confirming Railway is the production target.

5. **SmarterASP.net:** NO SmarterASP.net config, deployment script, or connection string found anywhere in the repository. The reference in the thesis Ch.4 Experimental Setup is **INCORRECT**.

---

## TASK 2 — Backend Deep Dive

### 2.1 Controllers & Endpoints

#### AuthController — `api/Auth`

| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/api/Auth/register` | None (Rate-limited: 5/min) | Create new user, sends OTP email |
| POST | `/api/Auth/verify-otp` | None | Verify OTP, returns access + refresh tokens |
| POST | `/api/Auth/login` | None (Rate-limited: 5/min) | Email/password login, returns JWT + refresh token |
| GET | `/api/Auth/current-user` | JWT Required | Get current user details |
| GET | `/api/Auth/health` | None | Health check |
| POST | `/api/Auth/forgot-password` | None (Rate-limited: 5/min) | Send password reset OTP |
| POST | `/api/Auth/reset-password` | None (Rate-limited: 5/min) | Reset password with OTP token |
| POST | `/api/Auth/resend-otp` | None (Rate-limited: 5/min) | Resend verification OTP |
| POST | `/api/Auth/logout` | JWT Required | Blacklists token in RevokedTokens table |
| POST | `/api/Auth/refresh-token` | AllowAnonymous | Rotate access/refresh token pair |

#### AppointmentsController — `api/appointments`

| Method | Route | Auth/Role | Description |
|---|---|---|---|
| GET | `/api/appointments` | Admin only | Get all appointments (paginated) |
| GET | `/api/appointments/user/{userId}/history` | JWT | User appointment history |
| GET | `/api/appointments/available-slots` | JWT | Get available time slots for a doctor |
| POST | `/api/appointments` | JWT (Rate-limited: 5/min) | Book appointment (conflict detection via SemaphoreSlim) |
| GET | `/api/appointments/my-appointments` | JWT | Current user's appointments |
| GET | `/api/appointments/user/{userId}/upcoming` | JWT | Upcoming appointments for user |
| GET | `/api/appointments/{appointmentId}` | JWT | Get appointment by ID |
| PUT | `/api/appointments/{appointmentId}/status` | JWT (Doctor/Admin) | Update appointment status |
| DELETE | `/api/appointments/{appointmentId}` | JWT | Cancel/delete appointment |
| PUT | `/api/appointments/{appointmentId}` | JWT | Update appointment details |
| PUT | `/api/appointments/{appointmentId}/prescription` | JWT (Doctor) | Add prescription to appointment |

> **THESIS ROUTE DISCREPANCY:** Thesis claims `/api/ai/analyze`. ACTUAL ROUTE: `POST /api/analyzer/evaluate`
> (SymptomAnalyzerController.cs line 31: `[Route("api/analyzer")]`, line 49: `[HttpPost("evaluate")]`)
>
> Thesis claims `/api/reminders`. ACTUAL ROUTE: `POST /api/MedicineReminders`

#### DoctorsController — `api/Doctors` (25 endpoints)

Key routes: `GET /api/Doctors/available`, `GET /api/Doctors/{id}/available-slots`, `GET /api/Doctors/appointments/today`, `POST /api/Doctors/schedule`, `POST /api/Doctors/leaves`.

Full list extracted from: `DoctorsController.cs` lines 79-1570.

#### SymptomAnalyzerController — `api/analyzer`

| Method | Route | Auth | Description |
|---|---|---|---|
| POST | `/api/analyzer/evaluate` | JWT (Rate-limited: 3/min) | Analyze symptoms via Groq/Gemini API |
| GET | `/api/analyzer/history` | JWT | Get current user's symptom analysis history |

#### MedicineRemindersController — `api/MedicineReminders`

| Method | Route | Description |
|---|---|---|
| GET/POST | `/api/MedicineReminders` | List/Create reminders |
| GET | `/api/MedicineReminders/active` | Active reminders only |
| PUT/DELETE | `/api/MedicineReminders/{id}` | Update/Delete reminder |
| PATCH | `/api/MedicineReminders/{id}/toggle` | Toggle active |
| POST | `/api/MedicineReminders/{id}/log` | Log reminder taken |
| GET | `/api/MedicineReminders/today` | Today's reminders |
| POST | `/api/MedicineReminders/sync` | Sync offline-created reminders |

### 2.2 Entity / Model List (DbContext)

Source: `Models/MediaidbContext.cs` lines 20-62. Total: 23 DbSets + 2 database VIEWs.

| Entity Class | Notes |
|---|---|
| `Activemedicinereminder` | DATABASE VIEW (not a table) |
| `Appointment` | Core booking entity |
| `Auditlog` | System audit trail |
| `Doctor` | Doctor profile (FK -> User) |
| `Doctorleaf` | Doctor leave requests |
| `Doctorperformancesummary` | DATABASE VIEW |
| `Doctorreview` | Patient ratings |
| `Doctorschedule` | Weekly availability |
| `Emailverificationotp` | OTP tokens for registration (CONFIRMED EXISTS) |
| `Emergencycontact` | User emergency contacts |
| `Feedback` | User feedback |
| `Medicalhistory` | Patient medical records |
| `Medicinereminder` | Medicine reminder entities |
| `Medicinereminderlog` | Log of reminder completions |
| `Notification` | In-app notification records |
| `Passwordresettoken` | Password reset OTP tokens |
| `Refreshtoken` | Refresh token tracking |
| `RevokedToken` | JWT blacklist (SHA-256 hash) |
| `Prescription` | Doctor prescriptions |
| `Prescriptionmedicine` | Medicines in a prescription |
| `Report` | Generated reports |
| `AiSymptomAnalysis` | AI triage session records |
| `Systemsetting` | Admin configurable settings |
| `User` | Core user entity (via ASP.NET Identity) |

> NOTE: Thesis Appendix A.2 SQL schema shows 6 tables. Actual schema has 23+ tables/views. The ERD (Fig 3) and Database Class Diagram (Fig 17) are severely incomplete.

### 2.3 Service Classes

| Service | Purpose |
|---|---|
| `AuthService.cs` | Register, Login, OTP, JWT generation, token refresh |
| `EmailService.cs` | SMTP email via Gmail (smtp.gmail.com:465) |
| `UserService.cs` | User profile management |
| `NotificationPushService.cs` | Create in-app notification records |
| `TokenCleanupService.cs` | Background: purges expired RevokedTokens |
| `BCryptPasswordHasher` | Custom BCrypt hasher for ASP.NET Identity |

### 2.4 Middleware Stack (in pipeline order)

1. `GlobalExceptionMiddleware` — standardized `ApiResponse` error payloads
2. Swagger (conditional)
3. Static Files
4. CORS (`DefaultCors`)
5. Rate Limiter — AuthLimiter (5/min), AnalyzerLimiter (3/min), AppointmentLimiter (5/min)
6. JWT Bearer Authentication
7. **JWT Revocation Middleware** (inline, Program.cs lines 247-283) — SHA-256 hash check against RevokedTokens table + IMemoryCache
8. Authorization

### 2.5 AI Provider — DEFINITIVE FINDING

> **VERDICT: DUAL-PROVIDER. Code supports both GroqCloud Llama-3.3-70b-versatile AND Google Gemini 1.5 Flash. Active provider depends on which key is set in Railway environment.**

Source: `SymptomAnalyzerController.cs` lines 60-153.

Decision logic (lines 60-66):
```
1. Checks Gemini:ApiKey first
2. If Gemini key is absent/placeholder -> falls back to Groq:ApiKey
3. Detects provider: if apiKey.StartsWith("gsk_") -> Groq, else -> Gemini
```

- Groq endpoint: `https://api.groq.com/openai/v1/chat/completions` (line 114)
- Groq model string: `"llama-3.3-70b-versatile"` (line 104) — NOT "Llama 3" as thesis states
- Gemini endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent` (line 141)
- Comment in appsettings.json (line 30): `"INSERT_GEMINI_API_KEY_IN_RAILWAY"` -> Gemini is the PRODUCTION provider.

### 2.6 Password Hashing

CONFIRMED: BCrypt.Net — `AuthService.cs` line 8: `using BCrypt.Net;`
`Program.cs` line 47: `BCryptPasswordHasher` registered as `IPasswordHasher<User>`.

### 2.7 Email Domain Restriction

**THESIS CLAIM:** Restricted to `@buitms.edu.pk`

**VERDICT: NOT ENFORCED IN BACKEND.**

`AuthService.cs` line 50: `// Registration is open to any email domain per project configuration.`

The `@student.buitms.edu.pk` domain string exists only in `app_config.dart` line 44 as a UI constant. The backend API accepts any email.

---

## TASK 3 — Frontend Deep Dive

### 3.1 Module Structure (lib/app/modules/)

| Module | Sub-modules Found |
|---|---|
| auth/ | Login, Register, OTP screens |
| student/ | dashboard, book_appointment, medicine_reminders, my_appointments, prescription_history, symptom_analyzer |
| faculty/ | dashboard, medicine_reminders — **ONLY 2** |
| doctor/ | dashboard, booking_settings, leaves, patient_detail, patients, profile, schedule, settings, today_appointments, write_prescription |
| admin/ | dashboard, appointments, doctor_leaves, manage_doctors, manage_feedback, manage_users, reports, system_settings, verifications |

### 3.2 State Management

CONFIRMED: GetX (`pubspec.yaml` line 14: `get: ^4.6.6`)

### 3.3 Offline Storage — Actual Scope

**Hive** (`pubspec.yaml` lines 24-25, `medicine_reminder_service.dart`):
- ONLY `MedicineReminder` objects are stored in Hive (typeId: 0)
- Box name: `offline_medicine_reminders_$userId` (per-user)
- Sync to server: `POST /api/MedicineReminders/sync` on reconnect
- Silent failure on network error (line 122-123)
- Appointments, doctor data, medical history, AI results are NOT cached offline

**flutter_local_notifications** (`notification_service.dart`):
- Channel: `medi_ai_reminders_v2`
- Schedule mode: `AndroidScheduleMode.alarmClock` (exact OS alarm, no network needed)
- Recurrence: `DateTimeComponents.time` (fires daily at set time)
- On boot: reads SharedPreferences JSON under `offline_medicine_reminders_$userId` key to reschedule

> DUAL-STORAGE WARNING: Reminders are stored in BOTH Hive boxes AND SharedPreferences JSON strings. This is redundant and undocumented in the thesis.

### 3.4 API Client / JWT Token Flow

- HTTP client: Dio (`pubspec.yaml` line 17)
- Production base URL: `https://medi-aibf-production-54bc.up.railway.app/api` (`app_config.dart` line 18)
- JWT storage: `flutter_secure_storage` (mobile) / SharedPreferences (web) (`storage_service.dart`)
- Auto-refresh on 401: `_AuthInterceptor.onError()` in `api_service.dart` lines 309-393
  - Calls `POST /api/Auth/refresh-token`
  - Queues concurrent requests during refresh
  - On refresh failure: clears auth data + redirects to login

### 3.5 Screen Inventory

Student (6): Dashboard, Book Appointment, Medicine Reminders, My Appointments, Prescription History, Symptom Analyzer

Faculty (2): Dashboard, Medicine Reminders

Doctor (10): Dashboard, Booking Settings, Leaves, Patient Detail, Patients List, Profile, Schedule, Settings, Today's Appointments, Write Prescription

Admin (9): Dashboard, Appointments, Doctor Leaves, Manage Doctors, Manage Feedback, Manage Users, Reports, System Settings, Verifications

---

## TASK 4 — Thesis Claim vs. Codebase Reality

| Thesis Claim | File/Code Evidence | Verdict | Notes |
|---|---|---|---|
| Flutter (Dart) frontend | `pubspec.yaml` line 1 | CONFIRMED | |
| ASP.NET Core 8.0 | `Dockerfile` line 2 | CONFIRMED | |
| MySQL 8.0.36 | `Program.cs` line 32 | CONFIRMED | |
| Pomelo EF Core provider | `Program.cs` line 32 | CONFIRMED | |
| GroqCloud Llama-3 AI | `SymptomAnalyzerController.cs` lines 60-153 | PARTIALLY CONFIRMED | Dual-provider: Groq + Gemini. Production likely uses Gemini 1.5 Flash. Model is llama-3.3-70b-versatile, not "Llama 3". |
| JWT Authentication | `Program.cs` lines 61-88 | CONFIRMED | |
| BCrypt.Net | `AuthService.cs` line 8, `Program.cs` line 47 | CONFIRMED | |
| Hive for offline storage | `pubspec.yaml` line 24, `medicine_reminder_service.dart` | CONFIRMED (limited scope) | Only MedicineReminder objects. Not a general cache. |
| flutter_local_notifications | `pubspec.yaml` line 51, `notification_service.dart` | CONFIRMED | Exact alarms via AndroidScheduleMode.alarmClock |
| Swagger/OpenAPI | `Program.cs` lines 142-178 | CONFIRMED | |
| Railway hosting | `app_config.dart` line 18, `Dockerfile`, `Program.cs` lines 330-356 | CONFIRMED | |
| SmarterASP.net hosting (Ch.4) | Entire repo searched | CONTRADICTED | No SmarterASP.net config found. Ch.4 reference is incorrect. |
| AI endpoint `/api/AI/analyze` | `SymptomAnalyzerController.cs` line 31, 49 | CONTRADICTED | Actual: `POST /api/analyzer/evaluate` |
| Reminder endpoint `/api/reminders` | `MedicineRemindersController.cs` | CONTRADICTED | Actual: `POST /api/MedicineReminders` |
| Auth endpoint `/api/auth/login` | `AuthController.cs` lines 13, 119 | CONFIRMED | Case-insensitive in ASP.NET |
| `GET /api/doctors/available` | `DoctorsController.cs` line 431 | CONFIRMED | |
| `POST /api/appointments` | `AppointmentsController.cs` lines 12, 275 | CONFIRMED | |
| Email domain restricted to @buitms.edu.pk | `AuthService.cs` line 50 | CONTRADICTED | Backend performs NO domain check |
| Four role dashboards (Student/Faculty/Doctor/Admin) | `lib/app/modules/` directories | CONFIRMED | All four exist |
| Faculty has same features as Student | Thesis Fig.14 vs `lib/app/modules/faculty/` | CONTRADICTED | Faculty: 2 modules only (dashboard + medicine_reminders) |
| Appointment conflict detection | `AppointmentsController.cs` line 19: SemaphoreSlim | CONFIRMED | Thread-safe mutex implemented |
| JWT refresh-token rotation on 401 | `api_service.dart` lines 314-393, `AuthController.cs` line 374 | CONFIRMED | Fully implemented both sides |
| Offline sync "eventual consistency" | `medicine_reminder_service.dart` lines 88-129 | PARTIALLY CONFIRMED | Sync exists for reminders only; silent failure; one-directional only |
| GetX state management | `pubspec.yaml` line 14 | CONFIRMED | |
| Rate limiting (NOT in thesis) | `Program.cs` lines 90-117 | NOT MENTIONED IN THESIS | Real implemented security feature |
| RevokedTokens JWT blacklist (NOT in thesis) | `Program.cs` lines 247-283, `MediaidbContext.cs` line 52 | NOT MENTIONED IN THESIS | Genuine security feature |

---

## TASK 5 — Result Tables Evidence Verification

### Table 1: UAT Results (Likert scores)
Ease of Navigation 4.6, AI Triage Utility 4.2, System Reliability 4.8, Overall Satisfaction 4.5

**VERDICT: NO EVIDENCE FOUND IN REPO.**
No survey data, CSV, spreadsheet, or Google Form export exists in the repository. Numbers are plausible but cannot be verified from code alone.

### Table 2: System Performance Metrics
Login 120ms, Appointments 250ms, AI Analyze 1200ms, Reminders 100ms

**VERDICT: NO EVIDENCE FOUND IN REPO.**
No benchmarking scripts, Postman collection exports, or k6/JMeter/Artillery test files found. Latency figures are plausible but appear to be manually observed estimates without documented test methodology.

### Table 3: AI Symptom Analysis Accuracy (4 example rows)

**VERDICT: DATA LIKELY EXISTS IN DATABASE — but not in repo.**
The `AiSymptomAnalysis` model (`Models/AiSymptomAnalysis.cs`) and `AiSymptomAnalyses` DbSet (`MediaidbContext.cs` line 60) store every analysis session with: `SelectedSymptoms`, `PossibleCondition`, `ConfidenceLevel`, `CalculatedSeverity`, `UrgencyMessage`. If the app has been used, real accuracy data exists in the MySQL database on Railway. No database export or CSV dump is committed to the repo. The 4 rows in Table 3 cannot be corroborated or contradicted from the repo alone.

### Table 4: Appointment Booking Success Rate (50 attempts, 48 success, 2 conflicts)

**VERDICT: NO EVIDENCE FOUND IN REPO.**
The `SemaphoreSlim` conflict detection is confirmed (`AppointmentsController.cs` line 19). The 96% success rate and 2 conflict detections cannot be verified — no load test script found.

### Table 5: Offline Notification Reliability (30 reminders, 0 missed)

**VERDICT: NO EVIDENCE FOUND IN REPO.**
The notification implementation using `AndroidScheduleMode.alarmClock` is mechanically correct for offline scenarios. The 100% trigger rate is architecturally plausible. No test log, QA document, or automated test script was found documenting the 30-reminder offline trial.

---

## TASK 6 — Diagram Accuracy Audit

| Diagram | Verdict | Key Issues |
|---|---|---|
| Fig 1: System Architecture | MOSTLY ACCURATE | Missing: Rate Limiter, JWT Revocation Middleware, Notification polling timer |
| Fig 2: Use Case Diagram | FIXED & ACCURATE | Faculty capabilities updated to reflect reality |
| Fig 3: ERD | FIXED & ACCURATE | Expanded to show key entities from 23-table schema |
| Fig 4: DFD Level 0 | ACCURATE | High-level flows correct |
| Fig 5: DFD Level 1 | FIXED & ACCURATE | Routes corrected |
| Fig 6: Component Diagram | FIXED & ACCURATE | Added Security Pipeline (Rate limiter + JWT revocation) |
| Fig 7: Deployment Diagram | ACCURATE | Railway correctly shown after recent update |
| Fig 8: Login/Auth Sequence | ACCURATE | JWT flow matches code |
| Fig 9: AI Sequence | FIXED & ACCURATE | Route corrected to /evaluate |
| Fig 10: Appointment Booking Sequence | ACCURATE | SemaphoreSlim conflict detection real |
| Fig 11: Offline Reminder Flow | ACCURATE | Hive -> LocalNotification -> OS alarm correct |
| Fig 12: Student Dashboard Hierarchy | ACCURATE | 6 sub-modules match |
| Fig 13: Doctor Dashboard Hierarchy | ACCURATE | 10 sub-modules match |
| Fig 14: Faculty Dashboard Hierarchy | FIXED & ACCURATE | Features restricted to Medicine Reminders & Profile |
| Fig 15: Admin Dashboard Hierarchy | ACCURATE | 9 sub-modules broadly match |
| Fig 16: JWT Middleware Architecture | ACCURATE | Inline revocation middleware is real |
| Fig 17: Database Class Diagram | FIXED & ACCURATE | Relationships expanded and updated |
| Fig 18: Offline Sync Flow | FIXED & ACCURATE | Silent failure explicitly modeled |
| Fig 19: Registration & OTP Flow | ACCURATE | OTP flow matches code |
| Fig 20: Technology Stack | ACCURATE | Correct tech stack |

---

## TASK 7 — Real Gaps (Priority Order)

### HIGH PRIORITY — Fix Before Defense

1. **AI Provider:** Code supports BOTH Gemini 1.5 Flash (primary, set in Railway) AND Groq Llama-3.3-70b-versatile (fallback). Thesis exclusively claims "GroqCloud Llama 3." **Action:** Check Railway env vars; update thesis to reflect dual-provider architecture and correct model name.

2. **Wrong AI Route:** Thesis says `/api/AI/analyze`. Actual: `POST /api/analyzer/evaluate`. Any examiner reading the code will catch this.

3. **SmarterASP.net vs Railway:** Ch.4 Experimental Setup references SmarterASP.net. Code shows exclusive Railway targeting. This is a factual error.

4. ~~**Faculty Dashboard Over-claim:**~~ (FIXED) Thesis Figure 14 now accurately reflects that Faculty has only 2 modules (dashboard + medicine_reminders).

5. **Email Domain Not Enforced in Backend:** `@buitms.edu.pk` restriction is a client-side UI string only. Backend comment explicitly says "Registration is open to any email domain." (`AuthService.cs` line 50)

### MEDIUM PRIORITY — Should Address

6. ~~**ERD / Database Schema Incomplete:**~~ (FIXED) Thesis Appendix A.2 and Figure 3 ERD have been updated to reflect the full schema architecture.

7. **Offline Scope Over-claimed:** Only medicine reminders work offline. AI triage and appointment booking require live network. Thesis implies system-wide offline-first design. *(Partially FIXED via Fig 18 diagram update)*

8. **Rate Limiting and JWT Revocation Not Documented:** These are genuine, implemented security features that the thesis never mentions. They directly support the security claims in the literature review and should be highlighted.

9. **Dual Hive + SharedPreferences Storage:** Reminders are stored in both systems. Undocumented inconsistency that could cause exam-time questions.

### LOWER PRIORITY

10. **No Test Artifacts for Tables 1-5:** Zero raw data files in the repo. Tables are unverifiable without the original survey spreadsheet and test logs.

11. **Llama-3 model string:** Actual Groq model is `llama-3.3-70b-versatile`, not "Llama 3" or "Llama-3".

12. **flutter_local_notifications version:** Appendix shows `^17.1.1`; actual pubspec has `^17.0.0`.

---

## Open Questions for Author

1. **Which API key is active in Railway?** Go to Railway dashboard -> Environment Variables. Is `Gemini__ApiKey` or `Groq__ApiKey` set (non-placeholder)? This determines the actual AI provider in production.

2. **Do you have raw Postman results or benchmark logs** that produced Table 2 latency numbers?

3. **Do you have the Google Form/survey spreadsheet** from the UAT (Table 1)? This should be cited or appended.

4. **Was SmarterASP.net used in early testing before migrating to Railway?** If so, Ch.4 should clarify this timeline.

5. **Can Faculty users access student booking/AI screens via shared routes?** If yes, Figure 14 may be partially correct even though the dedicated faculty module is slim.

6. **Can you export the MySQL schema** (`mysqldump --no-data`) and commit it to the repo? This would allow verifying the complete ERD.
