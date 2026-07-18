# Medi-AI — Complete Project Documentation
> **University:** BUITEMS Medical Center | **Project:** Final Year Project 2025–2026 | **App Version:** 1.0.0

This single file is the **complete reference** for the entire Medi-AI project — backend, frontend, database, flow, theme, routes, screens, controllers, bindings, services, and packages. Read it top to bottom once and you will understand the whole project.

---

## 0. What Is Medi-AI? (Non-Technical)

Medi-AI is a **University Medical Center Management System** built for BUITEMS. It connects four types of users — **Students**, **Faculty**, **Doctors**, and **Admins** — through a Flutter mobile/web app talking to an ASP.NET Core backend hosted on Railway, backed by a MySQL database.

A student can open the app, book an appointment with a campus doctor, get a diagnosis, receive a prescription, and review their full medical history — all without walking to the clinic first. The system also includes an AI-powered **Symptom Analyzer** that gives a preliminary assessment before the appointment.

---

## 1. Glossary

| Term | Plain-English Meaning |
|---|---|
| **Flutter** | Google's framework for building mobile + web apps from a single codebase |
| **GetX** | The state management + routing + dependency injection library the app uses |
| **Widget** | A visual building block on screen (button, text, card) |
| **Controller** | The "brain" of a screen — holds data and runs logic |
| **Binding** | Auto-loads the correct controller into memory when a screen opens |
| **Dio** | The HTTP client that sends requests over the internet |
| **Interceptor** | A checkpoint that adds the JWT to every request automatically |
| **JWT** | A digital ID card proving the user is logged in |
| **`.obs`** | A reactive variable — any widget using it auto-rebuilds when it changes |
| **Obx / GetBuilder** | Widgets that watch `.obs` variables and redraw when they change |
| **Hive** | A lightweight local database used on mobile for offline storage |
| **SharedPreferences** | Simple key-value local storage (used on web instead of Hive) |
| **FlutterSecureStorage** | Encrypted local storage on mobile — stores the JWT safely |
| **EF Core** | Backend's ORM — translates C# code into MySQL queries |
| **DTO** | Data Transfer Object — the JSON shape of a request/response |
| **Migration** | A version-control file that safely updates the database schema |
| **Railway** | The cloud platform hosting the ASP.NET backend + MySQL |

---

## 2. High-Level Architecture: How the Two Systems Connect

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (Frontend)                           │
│  Screen (Widget) → GetX Controller → ApiService (Dio) → Interceptor    │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │  HTTPS over internet
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   ASP.NET Core BACKEND (Railway)                        │
│  Kestrel → Rate Limiter → CORS → JWT Auth → Router → Controller        │
│        → Service Layer → EF Core (DbContext) → MySQL Database           │
└─────────────────────────────────────────────────────────────────────────┘
```

### The Full Round-Trip (Booking an Appointment Example)

| Step | What Happens | File Responsible |
|---|---|---|
| 1 | Student taps "Book Appointment" | `book_appointment_screen.dart` |
| 2 | Widget calls `controller.bookAppointment()` | `book_appointment_controller.dart` |
| 3 | Controller calls `ApiService.post('/appointments', data)` | `api_service.dart` |
| 4 | `_AuthInterceptor.onRequest()` reads JWT from `StorageService` | `api_service.dart` |
| 5 | Dio attaches `Authorization: Bearer <token>` header | `api_service.dart` |
| 6 | HTTPS POST hits Railway server | network |
| 7 | Kestrel receives packet | `Program.cs` |
| 8 | Rate Limiter, CORS, JWT Bearer validation | `Program.cs` |
| 9 | Router maps `/api/appointments` to `AppointmentsController` | `AppointmentsController.cs` |
| 10 | Controller validates DTO, checks doctor availability | `AppointmentsController.cs` |
| 11 | EF Core inserts `Appointments` row, writes `Notifications` row | `MediaidbContext` |
| 12 | MySQL confirms commit | database |
| 13 | Controller returns `ApiResponse<T>` JSON | `AppointmentsController.cs` |
| 14 | Dio receives 200 OK with JSON body | `api_service.dart` |
| 15 | `_AuthInterceptor.onResponse()` passes through | `api_service.dart` |
| 16 | Controller sets `isLoading.value = false`, `successMessage.value = ...` | `book_appointment_controller.dart` |
| 17 | `Obx` widget detects `.obs` change and redraws the success state | `book_appointment_screen.dart` |

---

## 3. Backend: Project Structure

```
Medi_AI_Backend_railway/
└── Backend-APIs/
    ├── Controllers/         ← HTTP endpoints (1 class per feature)
    ├── DTOs/                ← Shapes of JSON bodies (no database entity exposed directly)
    ├── Models/              ← EF Core database entity classes (1 class = 1 MySQL table)
    ├── Services/            ← Business logic & external integrations (Email, Auth, Push)
    ├── Middleware/          ← Global pipeline filters (exception handler)
    ├── Migrations/          ← Database schema history (Code-First EF Core)
    ├── Program.cs           ← Entry point: DI container, middleware pipeline, DB connect
    ├── appsettings.json     ← Config values (DB connection, JWT key — REDACTED in repo)
    └── Dockerfile           ← Railway build instructions
```

### Why Controllers ≠ Services
Controllers only handle HTTP routing and formatting responses. Services hold business rules. This means you can unit-test a Service without an HTTP request ever being made.

### Why DTOs ≠ Models
Models expose every database column. DTOs are whitelists of what the client can send or receive. If a client sends `{"Role":"Admin"}` in an update request, the DTO doesn't have a `Role` field, so EF Core never sees it — privilege escalation prevented.

---

## 4. Backend: Middleware Pipeline (Exact Order in `Program.cs`)

1. `app.UseRateLimiter()` — blocks brute-force (max 5 login attempts/minute per IP)
2. `app.UseCors("DefaultCors")` — validates request origin
3. `app.UseAuthentication()` — JwtBearer validates token signature + expiry
4. **Custom JWT Revocation** — checks `IMemoryCache["Blacklist_{token}"]`; if found → 401
5. `app.UseAuthorization()` — enforces `[Authorize(Roles = "...")]` attributes
6. `app.MapControllers()` — routes to the correct Controller + Action

---

## 5. Backend: Controllers & Endpoints

### `AuthController` — `/api/Auth`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/register` | None | Register a new user. Hashes password via BCrypt. Sends OTP email. |
| POST | `/send-otp` | None | Sends a 6-digit OTP to the provided email. |
| POST | `/verify-otp` | None | Validates OTP. Marks email as verified. |
| POST | `/login` | None | Validates credentials. Returns JWT + Refresh Token. |
| POST | `/refresh-token` | None | Exchanges a refresh token for a new access token. |
| POST | `/logout` | JWT | Blacklists the token in `IMemoryCache`. |
| POST | `/forgot-password` | None | Generates a reset token and emails it. |
| POST | `/reset-password` | None | Validates reset token and sets new password. |

### `UsersController` — `/api/users`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/profile` | JWT | Returns the logged-in user's profile from JWT `NameIdentifier`. |
| PUT | `/profile` | JWT | Updates address, phone number etc. (cannot change Role). |
| POST | `/change-password` | JWT | Updates password using BCrypt hashing. |
| POST | `/upload-photo` | JWT | Accepts multipart file; saves profile image URL. |

### `AppointmentsController` — `/api/Appointments`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/` | JWT | Admin: all appointments in the system. |
| POST | `/` | JWT | Books a new appointment. Checks doctor availability + leave blocks. |
| GET | `/my-appointments` | JWT | Returns appointments for the logged-in user. |
| GET | `/student/{id}/history` | JWT | Student appointment history. |
| GET | `/student/{id}/upcoming` | JWT | Upcoming student appointments. |
| GET | `/Faculty/appointments` | JWT | Faculty-specific appointment view. |
| GET | `/{id}` | JWT | Single appointment detail. |
| PUT | `/{id}/status` | JWT | State machine: Pending → Confirmed → Completed → Cancelled. Triggers notification. |
| PUT | `/{id}/prescription` | JWT | Doctor attaches a prescription string to a completed appointment. |
| PUT | `/{id}` | JWT | Edits appointment details. |
| DELETE | `/{id}` | JWT | Cancels and deletes an appointment. |

### `DoctorsController` — `/api/doctors`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/` | JWT | Lists all active doctors with specializations. |
| GET | `/{id}` | JWT | Single doctor profile. |
| POST | `/leaves` | JWT (Doctor) | Registers a leave block. Validates against existing appointments. |
| GET | `/leaves` | JWT (Doctor) | Doctor's own leave history. |
| PUT | `/leaves/{id}` | JWT (Doctor) | Modifies an existing leave. |
| DELETE | `/leaves/{id}` | JWT (Doctor) | Removes a leave block. |

### `NotificationsController` — `/api/notifications`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/my-notifications` | JWT | All notifications for the logged-in user. |
| GET | `/unread-count` | JWT | Integer count for badge UI. |
| PUT | `/{id}/read` | JWT | Marks one notification as read. |
| PUT | `/mark-all-read` | JWT | Batch-marks all notifications as read. |

### `AdminController` — `/api/admin`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| GET | `/dashboard-stats` | JWT (Admin) | Aggregated totals for charts. |
| GET | `/users` | JWT (Admin) | All users with filters/pagination. |
| POST | `/users` | JWT (Admin) | Creates a new user manually. |
| PUT | `/users/{id}` | JWT (Admin) | Updates any user. |
| DELETE | `/users/{id}` | JWT (Admin) | Removes a user. |
| PUT | `/verify-user/{id}` | JWT (Admin) | Verifies a user account. |
| GET | `/pending-verifications` | JWT (Admin) | All users pending verification. |
| GET | `/recent-activities` | JWT (Admin) | Audit log of recent actions. |
| GET | `/recent-users` | JWT (Admin) | Newly registered users. |
| GET | `/notifications` | JWT (Admin) | System-wide notification log. |
| GET | `/doctor-leaves` | JWT (Admin) | All doctor leaves across system. |
| GET | `/system-settings` | JWT (Admin) | Reads system configuration. |
| PUT | `/system-settings` | JWT (Admin) | Updates system configuration. |
| POST | `/clear-cache` | JWT (Admin) | Purges server memory cache. |
| POST | `/backup-database` | JWT (Admin) | Triggers a database snapshot. |

### `SymptomAnalyzerController` — `/api/analyzer`
| Method | Route | Auth | Purpose |
|---|---|---|---|
| POST | `/evaluate` | JWT | Sends symptom payload to Groq/Gemini LLM. Returns structured AI assessment. Writes to `AiSymptomAnalysis` table. |

---

## 6. Backend: NuGet Packages

| Package | Version | Role |
|---|---|---|
| `Pomelo.EntityFrameworkCore.MySql` | 8.0.2 | Translates LINQ → MySQL queries |
| `Microsoft.EntityFrameworkCore.Design` | 8.0.11 | Enables `dotnet ef migrations` CLI |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | 8.0.0 | Cryptographic JWT validation |
| `BCrypt.Net-Next` | 4.0.3 | Password hashing with automatic salting |
| `MailKit` | 4.17.0 | SMTP email sending (OTPs, registration emails) |
| `Swashbuckle.AspNetCore` | 6.5.0 | Swagger UI at `/swagger` for API testing |

---

## 7. Backend: Database Schema

### `Users`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | Auto-increment |
| `Email` | string | Unique. Must be `@student.buitms.edu.pk` for students |
| `PasswordHash` | string | BCrypt hash. Never stored in plaintext |
| `Role` | string | `Student`, `Doctor`, `Faculty`, `Admin` |
| `IsActive` | bool | false = account locked out |
| `IsEmailVerified` | bool | Must be true before login permitted |
| `ProfileImageUrl` | string? | URL of uploaded photo |

### `Doctors`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `UserId` | int FK → Users.Id | 1:1 relationship |
| `Specialization` | string | e.g., "General Physician" |
| `Experience` | int | Years |

### `Appointments`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `PatientId` | int FK → Users.Id | |
| `DoctorId` | int FK → Doctors.Id | |
| `AppointmentDate` | DateOnly | No timezone — hospital-local date |
| `AppointmentTime` | TimeOnly | No timezone — hospital-local time |
| `Status` | string | `Pending`, `Confirmed`, `Completed`, `Cancelled` |
| `Symptoms` | string? | Patient-described symptoms at booking time |

### `DoctorLeaves`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `DoctorId` | int FK → Doctors.Id | |
| `StartDate` | DateOnly | |
| `EndDate` | DateOnly | |
| `Reason` | string? | |

### `Prescriptions`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `AppointmentId` | int FK → Appointments.Id | 1:1 |
| `Diagnosis` | string | Medical condition |
| `Notes` | string? | Additional instructions |
| `FollowUpDate` | DateOnly? | Suggested follow-up |

### `PrescriptionMedicines`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `PrescriptionId` | int FK → Prescriptions.Id | |
| `MedicineName` | string | |
| `Dosage` | string | e.g., "500mg" |
| `Frequency` | string | e.g., "Twice daily" |
| `Duration` | string | e.g., "7 days" |

### `Notifications`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `UserId` | int FK → Users.Id | |
| `Title` | string | |
| `Message` | string | |
| `IsRead` | bool | Badge counter source |
| `Type` | string | `appointment`, `prescription`, etc. |

### `AiSymptomAnalysis`
| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `UserId` | int FK → Users.Id | |
| `SelectedSymptoms` | string | JSON array of symptom strings |
| `PossibleCondition` | string? | AI output |
| `SeverityLevel` | string? | `Low`, `Moderate`, `High` |
| `CreatedAt` | DateTime | UTC |

### `Todaysappointment`
> ⚠️ **ORPHANED** — This appears to be a database view. No active controller writes to it. Verify before deleting.

---

## 8. Backend: Data Relationship Map

```
Users ──────────────────────────────── 1:1 ──→ Doctors
Users (as Patient) ────────────────── 1:N ──→ Appointments
Doctors ────────────────────────────── 1:N ──→ Appointments
Doctors ────────────────────────────── 1:N ──→ DoctorLeaves
Appointments ─────────────────────── 1:1 ──→ Prescriptions
Prescriptions ───────────────────────1:N ──→ PrescriptionMedicines
Users ──────────────────────────────── 1:N ──→ Notifications
Users ──────────────────────────────── 1:N ──→ AiSymptomAnalysis
```

---

## 9. Frontend: Project Structure (`lib/`)

```
lib/
├── main.dart                        ← App entry point
├── config/
│   ├── app_config.dart              ← Base URLs, timeouts, JWT keys, endpoints
│   └── app_theme.dart               ← Colors, typography, global widget styles
├── app/
│   ├── routes/
│   │   ├── app_routes.dart          ← Route string constants (e.g., '/login')
│   │   └── app_pages.dart           ← Maps routes → Screen + Binding
│   ├── services/                    ← Global GetxService singletons (live forever)
│   │   ├── api_service.dart         ← Dio HTTP client + interceptors
│   │   ├── storage_service.dart     ← JWT/UserData persist (Secure Storage + SharedPrefs)
│   │   ├── auth_service.dart        ← Current user session state
│   │   ├── notification_service.dart ← flutter_local_notifications setup
│   │   ├── medicine_reminder_service.dart ← Schedules local reminder alerts
│   │   ├── appointment_event_service.dart ← Cross-screen event bus
│   │   ├── doctor_service.dart      ← Doctor-specific API helpers
│   │   └── verification_service.dart ← Email OTP verification helpers
│   ├── data/
│   │   └── models/                  ← Dart model classes for JSON parsing
│   └── modules/                     ← Feature modules (one folder per feature)
│       ├── auth/                    ← Login, Register, OTP, Password flows
│       ├── student/                 ← Student dashboard + all student features
│       ├── doctor/                  ← Doctor dashboard + all doctor features
│       ├── faculty/                 ← Faculty dashboard
│       ├── admin/                   ← Admin dashboard + all admin tools
│       └── common/                  ← Shared screens (Notifications, Settings, etc.)
```

### The 3-File Module Pattern
Every feature inside `modules/` uses exactly three files:

```
feature/
├── feature_screen.dart      ← Only draws UI. Contains zero business logic.
├── feature_controller.dart  ← Holds .obs variables. Calls ApiService. Runs logic.
└── feature_binding.dart     ← Tells GetX to create the controller when this screen opens.
```

*Why?* The screen can be redesigned completely without touching the logic. The controller can be tested without a screen. The binding prevents controllers leaking between screens.

---

## 10. App Boot Sequence (`main.dart` + `SplashController`)

```dart
// main.dart — what happens before the user sees anything
void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // Flutter engine ready
  await Hive.initFlutter();                     // Local database ready (mobile only)
  SystemChrome.setSystemUIOverlayStyle(...);   // Status bar transparent
  await SystemChrome.setPreferredOrientations([portrait]); // Lock portrait
  runApp(const MediAIApp());                   // Show the app (starts at /splash)
}
```

```dart
// SplashController — runs in background during the 2.5s logo display
Future<void> _initializeApp() async {
  final minimumSplashTime = Future.delayed(Duration(milliseconds: 2500));
  
  Get.put(await StorageService().init(), permanent: true);  // Load tokens from device
  Get.put(await ApiService().init(), permanent: true);       // Setup Dio HTTP client
  Get.put(await AuthService().init(), permanent: true);      // Check if still logged in
  Get.put(await NotificationService().init(), permanent: true); // Setup local alerts
  Get.put(await MedicineReminderService().init(), permanent: true); // Schedule reminders
  
  await notificationService.rescheduleSavedReminders(); // Restore after device reboot
  await minimumSplashTime;  // Wait for 2.5s to fully elapse

  // Route by role
  if (user.isDoctor) → Get.offAllNamed('/doctor-dashboard')
  if (user.isFaculty) → Get.offAllNamed('/faculty-dashboard')
  if (user.isAdmin) → Get.offAllNamed('/admin-dashboard')
  else → Get.offAllNamed('/student-dashboard')
  // Not logged in → Get.offAllNamed('/login')
}
```

---

## 11. App Theme & Design System (`lib/config/app_theme.dart`)

### Color Palette
| Token | Value | Used For |
|---|---|---|
| `primary` | `#004F8C` | Buttons, app bar, key UI elements |
| `accent` | `#FF6F00` | Highlights, warnings, call-to-action |
| `background` | `#F8FAFC` | App scaffold background |
| `surface` | `#FFFFFF` | Cards, input fields |
| `error` | `#DC2626` | Error states, border on invalid input |
| `success` | `#10B981` | Success banners, confirmed badges |
| `warning` | `#F59E0B` | Pending states, warnings |
| `info` | `#3B82F6` | Informational banners |
| `textPrimary` | `#1E293B` | Main body text |
| `textSecondary` | `#64748B` | Hints, labels, secondary info |
| `border` | `#E2E8F0` | Card outlines, input borders |

### Typography
- **Font Family:** `Google Fonts — Poppins` (applied globally)
- **h1:** 32px Bold — page titles
- **h2:** 24px Bold — section headings
- **h3:** 20px SemiBold — subheadings
- **bodyLarge:** 16px — main reading text
- **bodyMedium:** 14px — forms and labels
- **bodySmall:** 12px — captions and secondary info

### Material 3 Defaults
- `useMaterial3: true`
- All buttons have `elevation: 0` (flat design)
- Input fields: `filled: true`, white fill, 12px border radius
- Cards: `elevation: 0`, 16px border radius, `border` color outline
- App bars: transparent, white background, centered title, 0 elevation
- Transitions: `Transition.cupertino` (iOS-style slide), 300ms

---

## 12. Navigation & Route Map

All routes are named strings in `app_routes.dart`. `app_pages.dart` maps each string to a Screen + Binding.

### Auth Routes
| Route String | Screen | Controller |
|---|---|---|
| `/` (splash) | `SplashScreen` | `SplashController` |
| `/onboarding` | `OnboardingScreen` | `OnboardingController` |
| `/register-email` | `RegisterEmailScreen` | `RegisterEmailController` |
| `/otp-verification` | `OtpVerificationScreen` | `OtpVerificationController` |
| `/set-password` | `SetPasswordScreen` | `SetPasswordController` |
| `/login` | `LoginScreen` | `LoginController` |
| `/forgot-password` | `ForgotPasswordScreen` | `ForgotPasswordController` |

### Student Routes
| Route String | Screen | Controller |
|---|---|---|
| `/student-dashboard` | `StudentDashboardScreen` | `StudentDashboardController` |
| `/book-appointment` | `BookAppointmentScreen` | `BookAppointmentController` |
| `/my-appointments` | `MyAppointmentsScreen` | `MyAppointmentsController` |
| `/symptom-analyzer-input` | `AiSymptomInputScreen` | `AiSymptomInputController` |
| `/symptom-analyzer-result` | `AiSymptomResultScreen` | `AiSymptomResultController` |
| `/medicine-reminders` | `MedicineRemindersScreen` | `MedicineRemindersController` |
| `/medical-history` | `MedicalHistoryScreen` | `MedicalHistoryController` |
| `/emergency-contacts` | `EmergencyContactsScreen` | `EmergencyContactsController` |
| `/profile` | `ProfileScreen` | `ProfileController` |
| `/prescription-history` | `PrescriptionHistoryScreen` | `PrescriptionHistoryController` |

### Doctor Routes
| Route String | Screen | Controller |
|---|---|---|
| `/doctor-dashboard` | `DoctorDashboardScreen` | `DoctorDashboardController` |
| `/today-appointments` | `TodayAppointmentsScreen` | `TodayAppointmentsController` |
| `/patient-detail` | `PatientDetailScreen` | `PatientDetailController` |
| `/write-prescription` | `WritePrescriptionScreen` | `WritePrescriptionController` |
| `/patients` | `PatientsScreen` | `PatientsController` |
| `/schedule` | `ScheduleScreen` | `ScheduleController` |
| `/booking-settings` | `BookingSettingsScreen` | `BookingSettingsController` |
| `/doctor-profile` | `DoctorProfileScreen` | `DoctorProfileController` |
| `/doctor-settings` | `DoctorSettingsScreen` | `DoctorSettingsController` |
| `/doctor/leaves` | `DoctorLeavesScreen` | `DoctorLeavesController` |

### Faculty Routes
| Route String | Screen | Controller |
|---|---|---|
| `/faculty-dashboard` | `FacultyDashboardScreen` | `FacultyDashboardController` |
| `/medicine-reminders` | (shared with student) | — |

### Admin Routes
| Route String | Screen | Controller |
|---|---|---|
| `/admin-dashboard` | `AdminDashboardScreen` | `AdminDashboardController` |
| `/admin-appointments` | `AdminAppointmentsScreen` | `AdminAppointmentsController` |
| `/manage-users` | `ManageUsersScreen` | `ManageUsersController` |
| `/manage-doctors` | `ManageDoctorsScreen` | `ManageDoctorsController` |
| `/manage-feedback` | `ManageFeedbackScreen` | `ManageFeedbackController` |
| `/reports` | `ReportsScreen` | — |
| `/system-settings` | `SystemSettingsScreen` | `SystemSettingsController` |
| `/admin/doctor-leaves` | `AdminDoctorLeavesScreen` | `AdminDoctorLeavesController` |
| `/admin/verifications` | `AdminVerificationsScreen` | `AdminVerificationsController` |

### Common Routes
| Route String | Screen | Controller |
|---|---|---|
| `/notifications` | `NotificationsScreen` | `NotificationsController` |
| `/settings` | `SettingsScreen` | `SettingsController` |
| `/appointment-detail` | `AppointmentDetailScreen` | — (stateless, data passed via `Get.arguments`) |
| `/feedback` | `FeedbackScreen` | `FeedbackController` |

---

## 13. Frontend: Core Services

### `ApiService` (`lib/app/services/api_service.dart`)
The central Dio HTTP client. Initialized as a permanent `GetxService` at splash.

- **Base URL:** `https://medi-aibf-production.up.railway.app/api` (production) — or localhost in dev mode via `--dart-define=USE_LOCAL_BACKEND=true`
- **Timeouts:** `connectionTimeout: 60s`, `receiveTimeout: 60s`
- **Interceptors registered:**
  1. `_AuthInterceptor` — reads JWT from `StorageService`, attaches `Authorization: Bearer` header to every request
  2. `_LoggingInterceptor` — logs all requests/responses for debugging

**401 Handling Flow:**
1. `_AuthInterceptor.onError()` catches a `DioException` with status 401
2. Calls `ApiService.refreshToken()` which POSTs to `/Auth/refresh-token`
3. If refresh succeeds: saves new tokens, retries the original request
4. If refresh fails: calls `StorageService.clearAuthData()`, `Get.offAllNamed('/login')` — user is logged out

### `StorageService` (`lib/app/services/storage_service.dart`)
Dual-mode local persistence:
- **Mobile:** `FlutterSecureStorage` (AES encrypted) for JWT tokens and User JSON
- **Web:** `SharedPreferences` (fallback since Secure Storage is not available)

**What is stored:**

| Key (`AppConfig`) | What | When Written | When Cleared |
|---|---|---|---|
| `access_token` | JWT access token | On login | On logout / 401 fail |
| `refresh_token` | JWT refresh token | On login | On logout / 401 fail |
| `user_data` | User JSON (name, role, email) | On login | On logout |
| `onboarding_complete` | Boolean | After onboarding | Never |
| `remember_me_email` | Email string | If "Remember Me" ticked | On logout |
| `isNotificationsMuted` | Boolean | In settings | In settings |

### `AuthService` (`lib/app/services/auth_service.dart`)
Holds the reactive session state: `isAuthenticated.obs`, `currentUser.obs`. SplashController reads these to decide where to route.

### `NotificationService` (`lib/app/services/notification_service.dart`)
Configures `flutter_local_notifications`. Requests notification permission on first run. Also calls `rescheduleSavedReminders()` so medicine alerts survive device reboots.

### `MedicineReminderService` (`lib/app/services/medicine_reminder_service.dart`)
Schedules local OS-level repeating notifications using `flutter_local_notifications` + `timezone`. Runs a 30-second background polling timer to check for new or updated reminders from the backend.

### `AppointmentEventService` (`lib/app/services/appointment_event_service.dart`)
A `StreamController`-based event bus. When any controller changes an appointment status, it emits an event. Other controllers (like the dashboard) listen to this stream and refresh without requiring navigation.

---

## 14. Frontend: Packages (`pubspec.yaml`)

| Package | Version | Role |
|---|---|---|
| `get` | ^4.6.6 | State management, routing, DI |
| `dio` | ^5.4.0 | HTTP client with interceptor support |
| `flutter_secure_storage` | ^9.0.0 | Encrypted JWT storage on mobile |
| `shared_preferences` | ^2.2.2 | Simple key-value store (web + preferences) |
| `hive` | ^2.2.3 | Lightweight local NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive adapter for Flutter initialization |
| `path_provider` | ^2.1.2 | Finds device directories for Hive files |
| `google_fonts` | ^6.1.0 | Poppins font family across the app |
| `flutter_svg` | ^2.0.9 | SVG icon and illustration rendering |
| `shimmer` | ^3.0.0 | Loading skeleton animations |
| `lottie` | ^3.0.0 | JSON-based animations (splash, empty states) |
| `flutter_slidable` | ^3.0.1 | Swipeable list items with action buttons |
| `cached_network_image` | ^3.3.1 | Profile images with disk caching |
| `intl` | ^0.20.2 | Date/time formatting, localization |
| `email_validator` | ^2.1.17 | Email format validation |
| `logger` | ^2.0.2+1 | Structured console logging |
| `connectivity_plus` | ^5.0.2 | Detects internet connection status |
| `permission_handler` | ^11.2.0 | Requests notification, camera permissions |
| `flutter_local_notifications` | ^17.0.0 | Schedules offline medicine reminders |
| `timezone` | ^0.9.2 | TZ-aware scheduling for notifications |
| `fl_chart` | ^1.2.0 | Admin dashboard charts (bar, pie, line) |
| `url_launcher` | ^6.3.2 | Opens phone dialer, maps, email from the app |
| `flutter_markdown` | ^0.7.7+1 | Renders Markdown (AI result formatting) |
| `pin_code_fields` | ^8.0.1 | OTP input UI with auto-focus between boxes |
| `font_awesome_flutter` | ^10.6.0 | Extended icon set |
| `file_picker` | ^11.0.2 | Document/image selection for upload |
| `flutter_timezone` | ^5.1.0 | Gets device timezone string |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |
| `flutter_spinkit` | ^5.2.2 | Loading spinner animations |

---

## 15. Frontend: Screen-by-Screen Reference

### Auth Module

**`SplashScreen`** (`/`)
- Shows the Medi-AI logo for 2.5 seconds while services initialize in the background.
- Routes to the correct dashboard based on cached role, or to `/login`.
- *Controller:* `SplashController`

**`OnboardingScreen`** (`/onboarding`)
- Three-page introduction carousel explaining app features.
- Calls `StorageService.setOnboardingComplete()` on "Get Started" tap.
- *Controller:* `OnboardingController`

**`RegisterEmailScreen`** (`/register-email`)
- Accepts a BUITEMS email address (`@student.buitms.edu.pk` required).
- Calls `POST /api/Auth/send-otp`.
- *Controller:* `RegisterEmailController`

**`OtpVerificationScreen`** (`/otp-verification`)
- 6-digit PIN input using `pin_code_fields`.
- Calls `POST /api/Auth/verify-otp`.
- *Controller:* `OtpVerificationController`

**`SetPasswordScreen`** (`/set-password`)
- Creates account password after OTP is verified.
- Calls `POST /api/Auth/register`.
- *Controller:* `SetPasswordController`

**`LoginScreen`** (`/login`)
- Email + password fields. "Remember Me" toggle.
- Calls `POST /api/Auth/login`. Saves JWT + User to `StorageService`.
- *Controller:* `LoginController`

**`ForgotPasswordScreen`** (`/forgot-password`)
- Email entry → reset link sent via `POST /api/Auth/forgot-password`.
- *Controller:* `ForgotPasswordController`

---

### Student Module

**`StudentDashboardScreen`** (`/student-dashboard`)
- Quick-action cards: Book Appointment, AI Symptom Checker, My Appointments, Prescription History.
- Displays upcoming appointment summary.
- Calls `GET /api/appointments/my-appointments`, unread count via `GET /api/notifications/unread-count`.
- *Controller:* `StudentDashboardController`

**`BookAppointmentScreen`** (`/book-appointment`)
- Doctor selection dropdown, date picker (`DateOnly`), time slot picker.
- Shows doctor leaves to block unavailable dates.
- Calls `GET /api/doctors`, then `POST /api/appointments`.
- *Controller:* `BookAppointmentController`

**`MyAppointmentsScreen`** (`/my-appointments`)
- Tabbed list: Upcoming / Past / Cancelled.
- Calls `GET /api/appointments/my-appointments`.
- *Controller:* `MyAppointmentsController`

**`AiSymptomInputScreen`** (`/symptom-analyzer-input`)
- Multi-select symptom chips + severity dropdown + duration field.
- Passes payload to `AiSymptomResultScreen` via `Get.toNamed(..., arguments: data)`.
- Calls `POST /api/analyzer/evaluate`.
- *Controller:* `AiSymptomInputController`

**`AiSymptomResultScreen`** (`/symptom-analyzer-result`)
- Renders structured JSON from the backend:
  - Color-coded severity badge (Green = Low, Amber = Moderate, Red = High)
  - Possible condition title
  - Home care advice as a `ListView`
  - Recommended doctor type
  - "Book an Appointment" CTA button
- Uses `flutter_markdown` to render formatted AI text.
- *Controller:* `AiSymptomResultController`

**`PrescriptionHistoryScreen`** (`/prescription-history`)
- Lists all prescriptions for the logged-in patient.
- Calls `GET /api/appointments/my-appointments` (filter for completed with prescription).
- *Controller:* `PrescriptionHistoryController`

**`MedicalHistoryScreen`** (`/medical-history`)
- Patient's historical diagnoses and notes.
- *Controller:* `MedicalHistoryController`

**`MedicineRemindersScreen`** (`/medicine-reminders`)
- CRUD for scheduled medicine reminders.
- Uses `MedicineReminderService` to schedule OS-level alerts via `flutter_local_notifications`.
- *Controller:* `MedicineRemindersController`

**`EmergencyContactsScreen`** (`/emergency-contacts`)
- Stores emergency contacts locally.
- Tapping a contact opens native phone dialer via `url_launcher`.
- *Controller:* `EmergencyContactsController`

**`ProfileScreen`** (`/profile`)
- Editable profile form. Photo upload via `file_picker`.
- Calls `GET /api/users/profile`, `PUT /api/users/profile`, `POST /api/users/upload-photo`.
- *Controller:* `ProfileController`

---

### Doctor Module

**`DoctorDashboardScreen`** (`/doctor-dashboard`)
- Today's appointment count, patient queue preview, quick-actions.
- Calls `GET /api/Appointments/` filtered for doctor's appointments today.
- *Controller:* `DoctorDashboardController`

**`TodayAppointmentsScreen`** (`/today-appointments`)
- Chronological list of today's booked appointments.
- Accept/Decline buttons call `PUT /api/Appointments/{id}/status`.
- *Controller:* `TodayAppointmentsController`

**`WritePrescriptionScreen`** (`/write-prescription`)
- Rich form: diagnosis, medicine list (name, dosage, frequency, duration), follow-up date.
- Calls `PUT /api/Appointments/{id}/prescription`.
- *Controller:* `WritePrescriptionController`

**`PatientDetailScreen`** (`/patient-detail`)
- Full patient record: demographics, appointment history, prescriptions.
- *Controller:* `PatientDetailController`

**`PatientsScreen`** (`/patients`)
- Searchable list of all patients seen by this doctor.
- *Controller:* `PatientsController`

**`ScheduleScreen`** (`/schedule`)
- Weekly calendar view of the doctor's appointment slots.
- *Controller:* `ScheduleController`

**`BookingSettingsScreen`** (`/booking-settings`)
- Configures available time slots and consultation duration.
- *Controller:* `BookingSettingsController`

**`DoctorLeavesScreen`** (`/doctor/leaves`)
- Date range picker to register leave blocks.
- Validates against existing appointments.
- Calls `POST /api/doctors/leaves`, `GET /api/doctors/leaves`.
- *Controller:* `DoctorLeavesController`

---

### Faculty Module

**`FacultyDashboardScreen`** (`/faculty-dashboard`)
- Streamlined version of the student dashboard.
- Same appointment booking and medicine reminder access.
- *Controller:* `FacultyDashboardController`

---

### Admin Module

**`AdminDashboardScreen`** (`/admin-dashboard`)
- Stats cards + `fl_chart` bar/pie charts: total users, appointments today, pending verifications.
- Calls `GET /api/admin/dashboard-stats`.
- *Controller:* `AdminDashboardController`

**`AdminAppointmentsScreen`** (`/admin-appointments`)
- Full appointment list with filter/search.
- Calls `GET /api/Appointments/`.
- *Controller:* `AdminAppointmentsController`

**`ManageUsersScreen`** (`/manage-users`)
- Paginated user list. Activate/deactivate toggle per row.
- Calls `GET /api/admin/users`, `PUT /api/admin/users/{id}`.
- *Controller:* `ManageUsersController`

**`ManageDoctorsScreen`** (`/manage-doctors`)
- Doctor roster with specialization filters.
- *Controller:* `ManageDoctorsController`

**`AdminVerificationsScreen`** (`/admin/verifications`)
- List of users pending email verification.
- Calls `GET /api/admin/pending-verifications`, `PUT /api/admin/verify-user/{id}`.
- *Controller:* `AdminVerificationsController`

**`AdminDoctorLeavesScreen`** (`/admin/doctor-leaves`)
- System-wide view of all doctor leaves.
- Calls `GET /api/admin/doctor-leaves`.
- *Controller:* `AdminDoctorLeavesController`

**`SystemSettingsScreen`** (`/system-settings`)
- Reads and updates system-level configuration.
- Calls `GET /api/admin/system-settings`, `PUT /api/admin/system-settings`.
- *Controller:* `SystemSettingsController`

---

### Common Screens

**`NotificationsScreen`** (`/notifications`)
- Full notification feed. Mark-all-read button.
- Calls `GET /api/notifications/my-notifications`, `PUT /api/notifications/mark-all-read`.
- *Controller:* `NotificationsController`

**`SettingsScreen`** (`/settings`)
- Toggle notification mute. Change password. Logout.
- Calls `POST /api/users/change-password`.
- *Controller:* `SettingsController`

**`AppointmentDetailScreen`** (`/appointment-detail`)
- Read-only detail view. Data passed in via `Get.arguments`.
- No dedicated controller (stateless).

**`FeedbackScreen`** (`/feedback`)
- Star rating + text feedback submission.
- *Controller:* `FeedbackController`

---

## 16. Security Configuration

### Security Techniques & Architecture Flow
Medi-AI employs defense-in-depth security techniques across the stack to ensure data integrity and user privacy:

1. **JWT Authentication & Refresh Flow (Backend & Frontend):** On login, `AuthController` creates a signed JWT using `Jwt:Key` (secret). Claims include `NameIdentifier` (UserId), `Email`, `Role`. `StorageService` writes the JWT to `FlutterSecureStorage` (AES encrypted on Android via `encryptedSharedPreferences: true`). `_AuthInterceptor.onRequest()` adds `Authorization: Bearer <token>` to every Dio request. On 401, `_AuthInterceptor` securely catches the error, queues the request, and POSTs to `/Auth/refresh-token`.
2. **Token Blacklisting (Logout Revocation):** Upon logout, the JWT signature is hashed (SHA-256) and stored persistently in a `RevokedTokens` database table. A custom ASP.NET Core Middleware (`JwtRevocationMiddleware`) intercepts every request, checks an `IMemoryCache` (pre-loaded from the DB at startup for performance), and rejects blacklisted tokens to prevent replay attacks.
3. **Strict Role Normalization:** Roles are strongly typed via C# Constants (`UserRoles.cs`) and Dart Constants (`AppRoles.dart`), eliminating security holes caused by magic strings, casing errors, or typos.
4. **IDOR Protection:** Endpoints like appointment cancellation (`DELETE /api/appointments/{id}`) or profile updates strictly verify that `ClaimTypes.NameIdentifier` matches the requested resource's owner or an Admin override.
5. **Password Hashing:** Passwords are never stored in plaintext. They are salted and hashed utilizing modern cryptographic standards in the ASP.NET Identity pipeline (BCrypt).

### No Payment Gateway (Intentional Design Decision)
The system **deliberately has no commercial payment gateway** (no Stripe, no PayPal). Appointment clearance is handled entirely through:
- Internal state machine transitions (Pending → Confirmed → Completed)
- Direct hospital contact: the `url_launcher` package opens the native phone dialer to call the medical center directly
- Physical visit to pay at the hospital counter

This is not a gap — it is a deliberate decision matching BUITEMS Medical Center's on-campus operational model.

---

## 17. Current State & Known Gaps (Complete Project)

The application has recently undergone a massive hardening and backlog completion pass, reaching a highly stable state where all critical backlog items across the Student, Faculty, Doctor, and Admin dashboards have been resolved.

However, while the core architecture is stable, the following technical debts and functional gaps remain across the full stack:

### 17.1 Frontend Gaps
| Category | Issue | Risk |
|---|---|---|
| Stability | Pagination Missing: `ManageUsersScreen` and `AdminAppointmentsScreen` currently load all records into memory at once. | UI freezing and high memory usage at scale. |
| UX | Button Debouncing: Several primary action buttons (e.g., "Submit" on forms) lack strict debouncing `.obs` flags. | Duplicate API calls if the user rapidly double-taps. |
| UI | Responsive Overflow: The AI Symptom analyzer dynamic text rows occasionally lack `Expanded` wrappers. | Pixel `RenderFlex` overflow on smaller devices. |
| Stability | Silent Failures on Schema Changes: Missing rigorous null-checks in Dart model parsing (`.fromJson`). | Red screen runtime exceptions if backend schema changes. |
| Memory | Missing Disposals: `FacultyDashboardController` and others may not cleanly close StreamListeners or `TextEditingController`s in `onClose()`. | RAM growth over time. |

### 17.2 Backend Gaps
| Category | Issue | Risk |
|---|---|---|
| Integration | Decorative Communication: Placholders exist for 2FA and SMS/Email OTPs, but they are either decorative or only printed to console. | Requires real provider (e.g., SendGrid/Twilio) for production. |
| Integration | Stubbed AI / Fake Reports: `SymptomAnalyzerController` relies on hardcoded logic rather than a real LLM. Admin DB backup returns `501 Not Implemented`. | Core advertised features remain non-functional. |
| Infrastructure | File Storage Scalability: Profile pictures or documents currently rely on the ephemeral Railway container filesystem. | Files will disappear on server restarts unless migrated to S3/Blob storage. |
| Security | Rate Limiting: There is no global rate limiting applied to the API. | Vulnerability to brute-force attacks on auth endpoints. |

### 17.3 Database Gaps
| Category | Issue | Risk |
|---|---|---|
| Infrastructure | Data Retention & Archival: The `Auditlogs` and `RevokedTokens` tables will grow indefinitely. | Requires a cron job to automatically purge old records to prevent DB bloat. |
| Security | Soft Delete Integrity: User deletion uses a soft-delete (`IsActive = false`), but no EF Core Global Query Filters automatically hide inactive users. | Developers must remember to manually append `.Where(u => u.IsActive == true)`. |
| Performance | Missing Composite Indices: Heavy dashboard queries rely on basic indices. | Degrading performance as table row counts scale beyond thousands. |
| Cleanup | Orphaned Models: `Todaysappointment` model exists in EF Core but no active controller writes to it. | Unused tables inflate the schema footprint. |

---

*Generated from live codebase read — `main.dart`, `app_config.dart`, `app_theme.dart`, `app_routes.dart`, `app_pages.dart`, `storage_service.dart`, `api_service.dart`, `splash_controller.dart`, `pubspec.yaml`, `Backend-APIs.csproj`, all Controller files.*
