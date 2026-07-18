# Medi-AI — Shared Architecture Reference

> **Source**: `lib/app/` (Flutter frontend) and `Medi_AI_Backend_railway/Backend-APIs/` (ASP.NET Core backend)
> Every claim is traced to an actual source file.

---

## 1. Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend** | Flutter / Dart | GetX state management, Dio HTTP client, SharedPreferences local cache |
| **Backend** | ASP.NET Core 8 | RESTful API, JWT Bearer auth, EF Core with Pomelo MySQL provider |
| **Database** | MySQL (Railway) | EF Core Code-First, `MediaidbContext` DbContext |
| **AI** | Google Gemini / Groq API | Backend proxy — Flutter never calls AI APIs directly |

---

## 2. Auth Module

**Location**: `lib/app/modules/auth/`

### Screens

| Screen | Route | File |
|---|---|---|
| Splash | `/splash` | `splash/splash_screen.dart` |
| Onboarding | `/onboarding` | `onboarding/onboarding_screen.dart` |
| Login | `/login` | `login/login_screen.dart` |
| Register Email | `/register` | `register_email/register_email_screen.dart` |
| OTP Verification | `/otp-verification` | `otp_verification/otp_verification_screen.dart` |
| Set Password | `/set-password` | `set_password/set_password_screen.dart` |
| Forgot Password | `/forgot-password` | `forgot_password/forgot_password_screen.dart` |

### Auth Flow
1. **Splash** checks `SharedPreferences` for a cached JWT via `AuthService`
2. If token found → routes to role-based dashboard
3. If no token → routes to `/onboarding` then `/login`
4. **Login** posts `{ email, password }` to `POST /api/Auth/login` → receives `{ token, user }`
5. Token stored via `AuthService._saveToken()` in `SharedPreferences`
6. **Registration** is a 3-step wizard: Email → OTP → Set Password

### Backend Endpoints (`AuthController.cs`)

| Method | Route | Auth | Purpose |
|---|---|---|---|
| `POST` | `/api/Auth/login` | None | Validates credentials, returns JWT + user |
| `POST` | `/api/Auth/register` | None | Creates user, sends OTP email |
| `POST` | `/api/Auth/verify-otp` | None | Validates OTP, activates account |
| `POST` | `/api/Auth/resend-otp` | None | Resends OTP to email |
| `POST` | `/api/Auth/forgot-password` | None | Sends password reset OTP |
| `POST` | `/api/Auth/reset-password` | None | Updates password after OTP |
| `POST` | `/api/Auth/logout` | JWT | Adds token to IMemoryCache blacklist |
| `GET` | `/api/Auth/me` | JWT | Returns current user from token |

---

## 3. Backend Infrastructure

**Location**: `Medi_AI_Backend_railway/Backend-APIs/`

### Middleware (Program.cs)
- **JWT Bearer Authentication**: All protected controllers require `[Authorize]`
- **JWT Blacklist**: Token string stored in `IMemoryCache` on logout; custom middleware returns 401 if token is blacklisted
- **Rate Limiter (AuthLimiter)**: Applied to auth endpoints to prevent brute-force
- **CORS**: Configured to allow all origins (dev mode)

### Universal API Response Wrapper
```csharp
public class ApiResponse<T> {
    public bool Success { get; set; }
    public string Message { get; set; }
    public T? Data { get; set; }
    public object? Errors { get; set; }
}
```

### Controllers List

| File | Route Prefix | Role Guard |
|---|---|---|
| `AuthController.cs` | `/api/Auth` | None (public) |
| `AppointmentsController.cs` | `/api/appointments` | `[Authorize]` |
| `DoctorsController.cs` | `/api/doctors` | `[Authorize]` |
| `AdminController.cs` | `/api/Admin` | `[Authorize(Roles="admin,Admin")]` |
| `FeedbackController.cs` | `/api/Feedback` | `[Authorize]` |
| `MedicalHistoryController.cs` | `/api/MedicalHistory` | `[Authorize]` |
| `MedicineRemindersController.cs` | `/api/MedicineReminders` | `[Authorize]` |
| `EmergencyContactsController.cs` | `/api/EmergencyContacts` | `[Authorize]` |
| `NotificationsController.cs` | `/api/Notifications` | `[Authorize]` |
| `PrescriptionsController.cs` | `/api/Prescriptions` | `[Authorize]` |
| `SymptomAnalyzerController.cs` | `/api/analyzer` | `[Authorize]` |
| `FacultyController.cs` | `/api/Faculty` | `[Authorize]` |
| `UsersController.cs` | `/api/Users` | `[Authorize]` |
| `ReportsController.cs` | `/api/Reports` | `[Authorize]` |

---

## 4. Frontend Core Services

**Location**: `lib/app/services/`

| Service | Purpose |
|---|---|
| `AuthService` | Manages JWT, `currentUser` Rx object, login/logout lifecycle |
| `ApiService` | Dio wrapper — injects JWT in headers, parses `ApiResponse<T>` |
| `DoctorService` | All `/api/doctors/` calls (schedule, leaves, appointments, stats) |
| `MedicineReminderService` | Local scheduled notifications via `flutter_local_notifications` |
| `NotificationService` | Fetches unread notifications from `/api/Notifications/unread` |
| `AppointmentEventService` | `StreamController` bus — fires events on appointment changes so dashboards refresh |

---

## 5. GetX Routing

**Location**: `lib/app/routes/`

Each route has a `binding` that lazily injects its controller. Role-based routing in `AuthService` after login:
```dart
if (role == 'doctor')   Get.offAllNamed(AppRoutes.doctorDashboard);
if (role == 'faculty')  Get.offAllNamed(AppRoutes.facultyDashboard);
if (role == 'admin')    Get.offAllNamed(AppRoutes.adminDashboard);
else                    Get.offAllNamed(AppRoutes.studentDashboard);
```

---

## 6. Shared Screens (Common Module)

**Location**: `lib/app/modules/common/`

### 6.1 Notifications Screen
**File**: `notifications/notifications_screen.dart`

| Element | Details |
|---|---|
| AppBar | "Notifications", action: "Mark all read" TextButton |
| Body | RefreshIndicator > ListView.separated of notification cards |
| Card | CircleAvatar (color by type: primary/error/warning/success), title, message, timestamp, mark-one-read IconButton |
| Empty state | `notifications_none` icon + "No unread notifications" text |
| Icon logic | `type.contains("alert")` → error icon; `type.contains("warning")` → warning icon; `type.contains("success")` → success icon |

**API calls**:
- `GET /Notifications/unread` — loads list
- `PUT /Notifications/{id}/read` — marks one read
- `PUT /Notifications/mark-all-read` — marks all read

### 6.2 Feedback Screen
**File**: `feedback/feedback_screen.dart`

Two tabs via `DefaultTabController(length: 2)`:

**Tab 1 — Submit**:
- TextField: Subject
- TextField (maxLines: 6): Message
- ElevatedButton: "Submit Feedback" (disabled + shows spinner while submitting)

**Tab 2 — History**:
- RefreshIndicator > ListView.separated
- Each card: subject (bold), message, timestamp, status chip (Responded=teal / Pending=orange)
- If responded: AnimatedSize container with "Admin Response" in a teal-bordered box

**API calls**:
- `POST /api/Feedback` — submit; backend sets `Status="Pending"` and notifies all admin users
- `GET /api/Feedback/my-feedback` — load history (returns subject, message, adminResponse, status, createdAt, respondedAt)

### 6.3 Settings Screen
**File**: `settings/settings_screen.dart`

**Preferences Section** (stored in `SharedPreferences`):
- SwitchListTile: "Mute Notifications" — disables all medicine reminders
- SwitchListTile: "Push notifications" — appointment reminders
- SwitchListTile: "Medicine reminders" — medicine intake alerts

**About Section**:
- "Version: 1.0.0"
- "Medi-AI Healthcare Platform — Final Year Project - BUITEMS"
- "Contact Developer" (tappable)

**Bottom**: Red ElevatedButton "Logout"

---

## 7. Shared Database Tables

**Source**: `Migrations/MediaidbContextModelSnapshot.cs`

| Table | Key Columns | Notes |
|---|---|---|
| `users` | `Id`, `FullName`, `Email`, `PasswordHash`, `Role`, `PhoneNumber`, `Department`, `RegistrationNumber`, `DateOfBirth`, `Gender`, `ProfileImageUrl`, `IsActive`, `IsEmailVerified`, `CreatedAt` | `Role` is a plain string: "Student", "Faculty", "Doctor", "Admin" |
| `notifications` | `Id`, `UserId` (FK→users), `Title`, `Message`, `Type`, `RelatedEntityId`, `RelatedEntityType`, `IsRead`, `CreatedAt` | Push notification records per user |
| `feedbacks` | `Id`, `UserId` (FK→users), `Subject`, `Message`, `AdminResponse`, `Status`, `CreatedAt`, `RespondedAt` | Status: "Pending" or "Responded" |
| `auditlogs` | `Id`, `UserId`, `Action`, `EntityType`, `EntityId`, `OldValues`, `NewValues`, `CreatedAt` | Used by Admin "Recent Activity" |
| `systemsettings` | `Id`, `SettingKey`, `SettingValue` | KV store for global admin config and per-doctor booking JSON (key prefix: `DoctorBookingSettings:{doctorId}`) |

---

## 8. Resolved Architecture Gaps

| # | Original Issue | Resolution |
|---|---|---|
| 1 | JWT blacklist is in-memory only | Implemented DB-backed revocation using the `RevokedTokens` table with memory cache preload. |
| 2 | Role stored as plain string | Refactored to use `UserRoles` (C#) and `AppRoles` (Dart) constants. Enforced across endpoints. |
| 3 | No refresh token | **Invalid claim.** Verified `api_service.dart` handles 401s and utilizes `POST /api/Auth/refresh-token` correctly. |
| 4 | SharedPreferences for settings | **Accepted behavior.** Local settings are kept device-local by design. |
