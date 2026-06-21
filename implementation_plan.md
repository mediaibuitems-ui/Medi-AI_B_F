# 🚀 Medi-AI — 5-Day Production Readiness Plan
### Complete Module-Level Fix & Verification Plan (Frontend + Backend)

> **Objective**: Take the Medi-AI project from its current state to a fully functional, secure, production-ready system — fixing all critical bugs, completing missing features, and hardening security across both the Flutter frontend and ASP.NET Core backend.

---

## 📋 Master Overview

| Day | Focus | Priority | Effort |
|---|---|---|---|
| **Day 1** | Critical Bug Fixes — App Cannot Function Without These | 🔴 Blocker | 8–10 hrs |
| **Day 2** | Security Hardening + Auth Flow Completion | 🔴 Critical | 8 hrs |
| **Day 3** | Frontend — Complete All Module Flows | 🟡 High | 8 hrs |
| **Day 4** | Backend — Complete All API Gaps + Notifications | 🟡 High | 8 hrs |
| **Day 5** | Testing, Polish & Production Deployment | 🟢 Final | 8 hrs |

---

## ⚡ DAY 1 — Critical Blocker Fixes
> **Goal**: Fix the bugs that completely break the app. After Day 1, the app must be able to login, register, and navigate without crashing.

---

### 🔧 BLOCK 1.1 — Fix Double `/api` Prefix Bug
**Severity**: 🔴 CRITICAL — ALL auth calls return 404
**Files to Modify**: `lib/app/services/auth_service.dart`

**The Problem**: `AppConfig.baseUrl` = `https://.../api`. The code passes `'${AppConfig.baseUrl}/Auth/login'` to `_apiService.post()`, making the final URL `.../api/api/Auth/login` — 404 error on every call.

**Fix**: Replace all absolute URL calls with relative paths in `auth_service.dart`.

**All 9 occurrences to fix**:

| Line | Current (WRONG) | Fixed (CORRECT) |
|---|---|---|
| register() | `'${AppConfig.baseUrl}/Auth/register'` | `'/Auth/register'` |
| resendOtp() | `'${AppConfig.baseUrl}/Auth/resend-otp'` | `'/Auth/resend-otp'` |
| verifyOtp() | `'${AppConfig.baseUrl}/Auth/verify-otp'` | `'/Auth/verify-otp'` |
| login() | `'${AppConfig.baseUrl}/Auth/login'` | `'/Auth/login'` |
| logout() | `'${AppConfig.baseUrl}/Auth/logout'` | `'/Auth/logout'` |
| getCurrentUser() | `'${AppConfig.baseUrl}/Auth/current-user'` | `'/Auth/current-user'` |
| forgotPassword() | `'${AppConfig.baseUrl}/Auth/forgot-password'` | `'/Auth/forgot-password'` |
| resetPassword() | `'${AppConfig.baseUrl}/Auth/reset-password'` | `'/Auth/reset-password'` |

**Verification**: Run the app. Login should return 200 OK instead of 404.

---

### 🔧 BLOCK 1.2 — Fix All Empty GetX Bindings
**Severity**: 🔴 CRITICAL — Controllers not found, screens crash
**Files to Modify**: Multiple binding files

#### Status of Each Binding (Audited)

| Binding File | Status | Action Required |
|---|---|---|
| `auth/splash/splash_binding.dart` | ✅ Fixed — `Get.put<SplashController>` | None |
| `auth/login/login_binding.dart` | ✅ Fixed — `Get.lazyPut<LoginController>` | None |
| `auth/register_email/register_email_binding.dart` | ❓ Check | Verify controller injection |
| `auth/otp_verification/otp_verification_binding.dart` | ❓ Check | Verify controller injection |
| `auth/forgot_password/forgot_password_binding.dart` | ❓ Check | Verify controller injection |
| `student/dashboard/student_dashboard_binding.dart` | ✅ Fixed | None |
| `student/book_appointment/book_appointment_binding.dart` | ❓ Check | Verify `BookAppointmentController` |
| `student/my_appointments/my_appointments_binding.dart` | ❓ Check | Verify controller |
| `student/medicine_reminders/medicine_reminders_binding.dart` | ❌ EMPTY | **Add controller injection** |
| `student/medical_history/medical_history_binding.dart` | ❓ Check | Verify controller |
| `student/emergency_contacts/emergency_contacts_binding.dart` | ❓ Check | Verify controller |
| `student/profile/profile_binding.dart` | ❓ Check | Verify controller |
| `student/ai_symptom_checker/ai_symptom_checker_binding.dart` | ❓ Check | Verify controller |
| `doctor/dashboard/doctor_dashboard_binding.dart` | ✅ Fixed | None |
| `doctor/write_prescription/write_prescription_binding.dart` | ❌ EMPTY | **Add controller injection** |
| `doctor/today_appointments/` | ❓ Check | Verify binding exists |
| `doctor/schedule/` | ❓ Check | Verify binding |
| `doctor/booking_settings/` | ❓ Check | Verify binding |
| `admin/dashboard/admin_dashboard_binding.dart` | ❓ Check | Verify binding |
| `admin/manage_feedback/manage_feedback_binding.dart` | ❓ Check | Verify binding |
| `common/notifications/notifications_binding.dart` | ✅ Has controller | None |
| `_bindings.dart` (global file) | ❌ ALL EMPTY | **Fix or remove** |

**Action for every empty binding** — add the correct controller:
```dart
class MedicineRemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MedicineReminderService(), fenix: true);
    Get.lazyPut(() => MedicineRemindersController());
  }
}
```

**Action for `_bindings.dart`**: This global file is a duplicate/legacy. Most modules now have their own binding files. Either:
- **Option A** (Recommended): Delete `_bindings.dart` and ensure every module has its own binding file
- **Option B**: Use it to hold truly global service bindings only

---

### 🔧 BLOCK 1.3 — Add Missing `settings` Route & Screen
**Severity**: 🔴 CRASH — `Get.toNamed('/settings')` has no destination
**Files to Create/Modify**:

1. **Create**: `lib/app/modules/common/settings/settings_screen.dart`
   - Simple screen: notification mute toggle, theme (if any), about section
2. **Create**: `lib/app/modules/common/settings/settings_binding.dart`
   - Inject a `SettingsController`
3. **Create**: `lib/app/modules/common/settings/settings_controller.dart`
   - Handles `NotificationService.setNotificationsMuted()`
4. **Modify**: `lib/app/routes/app_pages.dart`
   - Add `GetPage(name: AppRoutes.settings, page: () => SettingsScreen(), binding: SettingsBinding())`

---

### 🔧 BLOCK 1.4 — Remove All `print()` Debug Statements
**Severity**: 🟡 Security/Quality
**Files to Modify**: `auth_service.dart`, `splash_controller.dart`, and any other files with raw `print()` calls

**Search entire codebase for `print(` and replace with `_logger.d(...)` or remove**:

```bash
# Run this to find all print statements
grep -rn "print(" lib/
```

Replace all instances:
```dart
// BEFORE
print('📤 Sending registration data: $email');

// AFTER
_logger.d('Sending registration data: ${email.substring(0, 3)}***'); // Never log full sensitive data
```

---

## 🔐 DAY 2 — Security Hardening + Auth Flow Completion
> **Goal**: Secure all attack surfaces. Complete the forgot-password flow. Make the app safe for real users.

---

### 🔒 BLOCK 2.1 — Remove Secrets from Source Code
**Severity**: 🔴 CRITICAL SECURITY — Gmail password & Gemini API key exposed in Git

**Backend — `appsettings.json`**:
```json
// REMOVE these values from appsettings.json:
"Password": "glgegntspkwijpcz",       // Gmail App Password
"ApiKey": "AIzaSyDqD4cWtjUZ23As68cbwR_dRif6PECBg04"  // Gemini Key
```

**Add to `appsettings.json`** (blank placeholders only):
```json
{
  "EmailSettings": { "Password": "" },
  "Gemini": { "ApiKey": "" }
}
```

**Set as Railway Environment Variables** (Railway dashboard):
```
EmailSettings__Password=glgegntspkwijpcz
Gemini__ApiKey=AIzaSyDqD4cWtjUZ23As68cbwR_dRif6PECBg04
Jwt__Key=d3be9049-490d-4f40-ab13-66d187e2f290ef90b42c-934e-4bd3-a11d-71e8d55c6812
ConnectionStrings__DefaultConnection=<railway-mysql-url>
```

**Add to `.gitignore`** in backend:
```
appsettings.Development.json
*.local.json
```

---

### 🔒 BLOCK 2.2 — Gate Swagger Behind Development Mode
**Severity**: 🔴 Security — All API internals exposed publicly
**File to Modify**: `Program.cs`

```csharp
// CURRENT (WRONG - always on):
app.UseSwagger();
app.UseSwaggerUI(...);

// FIXED - only in Development:
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "MediAI API v1");
    });
}
```

---

### 🔒 BLOCK 2.3 — Implement Token Revocation on Logout
**Severity**: 🔴 Security — Stolen tokens remain valid 24h after logout
**Files to Modify**: `AuthController.cs`, `AuthService.cs`, `IAuthService.cs`

**Backend changes**:
1. `AuthController.cs` — `Logout()` endpoint: Extract JWT, call `_authService.RevokeTokenAsync(userId, refreshToken)`
2. `AuthService.cs` — `RevokeTokenAsync()`: Find and update the refresh token record in DB (`IsRevoked = true`, `RevokedAt = DateTime.UtcNow`)
3. `AuthService.cs` — `LoginAsync()`: Check `IsRevoked` on refresh tokens. If already revoked — force logout.

**Frontend change**:
- `auth_service.dart` — `logout()`: Already calls `POST /Auth/logout`. ✅ No change needed on Flutter side.

---

### 🔒 BLOCK 2.4 — Add API Rate Limiting on Auth Endpoints
**Severity**: 🟡 Security — Brute-force on login/register/OTP endpoints
**File to Modify**: `Program.cs`

Add ASP.NET Core 8 built-in rate limiting:
```csharp
// In Program.cs, add:
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("auth", config =>
    {
        config.PermitLimit = 10;
        config.Window = TimeSpan.FromMinutes(1);
        config.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        config.QueueLimit = 0;
    });
});

// On auth endpoints, add [EnableRateLimiting("auth")] attribute to:
// - Register, Login, VerifyOtp, ForgotPassword, ResendOtp
```

---

### 🔒 BLOCK 2.5 — Enforce Email Domain Validation (Frontend)
**Severity**: 🟡 Feature — BUITEMS-only platform not enforced
**File to Modify**: `lib/app/modules/auth/register_email/register_email_screen.dart` (and/or controller)

**Add validation**:
```dart
// In registration form validator:
if (!email.endsWith(AppConfig.allowedEmailDomain)) {
  return 'Only BUITEMS student emails (@student.buitms.edu.pk) are allowed';
}
```

**Also validate on backend** — `AuthService.cs` `RegisterAsync()`:
```csharp
if (!registerDto.Email.EndsWith("@student.buitms.edu.pk") &&
    !registerDto.Email.EndsWith("@buitms.edu.pk")) // allow faculty/staff domain
{
    return (false, "Only BUITEMS email addresses are allowed.");
}
```

---

### ✅ BLOCK 2.6 — Verify Complete Auth Flow End-to-End
**Action**: Manually test every auth screen and confirm data flows correctly

| Flow | Test | Expected |
|---|---|---|
| Register (Student) | Fill form → Submit | OTP email received |
| OTP Verify | Enter OTP | JWT stored, routed to dashboard |
| Login (existing) | Email + pass | JWT stored, correct dashboard |
| Forgot Password | Email + phone + CMS | Reset token returned |
| Reset Password | New password | Can login with new password |
| Token Refresh | Wait 24h / expire token | Auto-refreshed silently |
| Logout | Tap logout | Token cleared, routed to login |

---

## 📱 DAY 3 — Frontend — Complete All Module Flows
> **Goal**: Every screen must load real data from the backend and be fully interactive. No placeholder data.

---

### 📱 BLOCK 3.1 — Auth Module (Complete)

#### Files in `lib/app/modules/auth/`

| File | Status | Action |
|---|---|---|
| `splash/splash_screen.dart` | ✅ Works | Test animation timing |
| `splash/splash_controller.dart` | ✅ Works | Remove `print()` on line 62 |
| `splash/splash_binding.dart` | ✅ Works | None |
| `onboarding/onboarding_screen.dart` | ✅ Works | Verify content is correct |
| `register_email/register_email_screen.dart` | ⚠️ Check | Add BUITEMS email domain validator |
| `register_email/register_email_binding.dart` | ❓ Verify | Ensure controller is injected |
| `otp_verification/otp_verification_screen.dart` | ✅ Works | Test resend OTP timer |
| `set_password/set_password_screen.dart` | ✅ Works | Verify password strength rules |
| `login/login_screen.dart` | ✅ Works | Test error display after fix |
| `login/login_binding.dart` | ✅ Works | None |
| `login/login_controller.dart` | ✅ Works | None |
| `forgot_password/forgot_password_screen.dart` | ✅ Works | Test full flow end-to-end |
| `forgot_password/forgot_password_binding.dart` | ❓ Verify | Ensure controller injected |

---

### 📱 BLOCK 3.2 — Student Module (Complete)

#### Files in `lib/app/modules/student/`

**`dashboard/`**

| File | Status | Action |
|---|---|---|
| `student_dashboard_screen.dart` | ✅ Works | Verify all API data loads |
| `student_dashboard_controller.dart` | ✅ Works | Remove any `print()` calls |
| `student_dashboard_binding.dart` | ✅ Fixed | None |

**`book_appointment/`**

| File | Status | Action |
|---|---|---|
| `book_appointment_screen.dart` | ✅ Works | Test slot selection UX |
| `book_appointment_controller.dart` | ✅ Works | Verify doctor list loads from API |
| `book_appointment_binding.dart` | ❓ Verify | Confirm `BookAppointmentController` injected |

**`my_appointments/`**

| File | Status | Action |
|---|---|---|
| `my_appointments_screen.dart` | ⚠️ Short | Screen is only 2662 bytes — likely incomplete UI |
| `my_appointments_controller.dart` | ✅ Works | Verify cancellation and status update calls |
| `my_appointments_binding.dart` | ❓ Verify | Confirm controller injected |

**Action for `my_appointments_screen.dart`**:
- Verify it shows tabs: Upcoming / Past / Cancelled
- Each appointment card must show: Doctor name, date, time, status, specialty
- Add "View Prescription" button if appointment is Completed

**`ai_symptom_checker/`**

| File | Status | Action |
|---|---|---|
| `ai_symptom_checker_screen.dart` | ✅ Works | Test AI response display |
| `ai_symptom_checker_controller.dart` | ✅ Works | Verify API call to `/api/ai/analyze` |
| `ai_symptom_checker_binding.dart` | ✅ Works | None |

**`medicine_reminders/`**

| File | Status | Action |
|---|---|---|
| `medicine_reminders_screen.dart` | ✅ Works | Test add/edit/delete/schedule |
| `medicine_reminders_binding.dart` | ❌ EMPTY | **Fix: Add MedicineReminderService + Controller** |

Fix `medicine_reminders_binding.dart`:
```dart
class MedicineRemindersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MedicineReminderService>()) {
      Get.lazyPut(() => MedicineReminderService(), fenix: true);
    }
    if (!Get.isRegistered<NotificationService>()) {
      Get.lazyPut(() => NotificationService(), fenix: true);
    }
  }
}
```

**`medical_history/`** — Verify binding, controller, and screen all work with real API.

**`emergency_contacts/`** — Verify CRUD operations work end-to-end.

**`profile/`** — Verify photo upload, name change, phone change save correctly.

#### 🆕 CREATE: `student/prescriptions/` (Missing Feature — GAP-11)

| File | Action |
|---|---|
| `prescriptions_screen.dart` | **CREATE** — List all prescriptions for the logged-in student |
| `prescriptions_controller.dart` | **CREATE** — Fetch from `/api/Appointments` (filter completed) |
| `prescriptions_binding.dart` | **CREATE** — Inject controller |

**Route**: Add `static const prescriptions = '/my-prescriptions';` to `app_routes.dart` and register in `app_pages.dart`.

**Backend endpoint to use**: `GET /api/Appointments` (filter by `Status = "Completed"` and include `Prescription` navigation property).

---

### 📱 BLOCK 3.3 — Doctor Module (Complete)

#### Files in `lib/app/modules/doctor/`

**`dashboard/`**

| File | Status | Action |
|---|---|---|
| `doctor_dashboard_screen.dart` | ✅ Works | Verify stats & today's count |
| `doctor_dashboard_controller.dart` | ✅ Works | Verify appointment refresh |
| `doctor_dashboard_binding.dart` | ✅ Fixed | None |

**`today_appointments/`**

| File | Status | Action |
|---|---|---|
| `today_appointments_screen.dart` | ✅ Works | Test accept/reject buttons |
| Binding | ❓ Check | Verify `TodayAppointmentsBinding` |

**`write_prescription/`**

| File | Status | Action |
|---|---|---|
| `write_prescription_screen.dart` | ✅ Works | Test prescription save |
| `write_prescription_binding.dart` | ❌ EMPTY | **Fix: Add controller injection** |

**Fix `write_prescription_binding.dart`**:
```dart
class WritePrescriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WritePrescriptionController());
  }
}
```
> **NOTE**: `WritePrescriptionController` may not exist yet — check if logic is directly in the screen. If so, extract it to a controller.

**`patient_detail/`** — Verify patient medical history and appointment history loads.

**`schedule/`** — Verify weekly schedule can be set and saved.

**`booking_settings/`** — Verify consultation duration, advance booking days, etc., save.

**`patients/`** — Verify patient search and list work.

---

### 📱 BLOCK 3.4 — Admin Module (Complete)

#### Files in `lib/app/modules/admin/`

| Screen | Status | Action |
|---|---|---|
| `dashboard/admin_dashboard_screen.dart` | ✅ Works | Verify all stats load |
| `manage_users/manage_users_screen.dart` | ✅ Works | Verify filter, search, toggle status |
| `manage_doctors/manage_doctors_screen.dart` | ✅ Works | Verify doctor CRUD |
| `manage_feedback/manage_feedback_screen.dart` | ✅ Works | Verify feedback list |
| `reports/reports_screen.dart` | ❌ No backend | **Scope: Show basic stats until Day 4 backend is done** |
| `system_settings/system_settings_screen.dart` | ✅ Works | Verify save — note 2FA is cosmetic |

---

### 📱 BLOCK 3.5 — Faculty Module (Complete)

#### Files in `lib/app/modules/faculty/`

| File | Status | Action |
|---|---|---|
| `dashboard/faculty_dashboard_screen.dart` | ❓ Check | Verify screen is not empty |
| `dashboard/faculty_dashboard_binding.dart` | ❓ Check | Verify controller injected |
| `medicine_reminders/` | Shared with Student | Verify `offline_faculty_medicine_reminders` key used correctly |

**Gap**: Faculty has no appointment booking feature. Either:
- **Option A**: Route faculty to the same student appointment booking flow (simplest)
- **Option B**: Create a separate faculty booking flow

**Recommended**: Add `facultyBookAppointment = bookAppointment` alias in `app_routes.dart` (same screen, different role).

---

### 📱 BLOCK 3.6 — Common Module (Complete)

| File | Status | Action |
|---|---|---|
| `notifications/notifications_screen.dart` | ✅ Works | Verify marks-as-read works |
| `notifications/notifications_controller.dart` | ✅ Works | Verify polling or refresh on enter |
| `notifications/notifications_binding.dart` | ✅ Works | None |
| `feedback/feedback_screen.dart` | ✅ Works | Verify form submits |
| `feedback/feedback_binding.dart` | ✅ Works | None |
| `appointment_detail_screen.dart` | ✅ Works | Verify all data shows |
| **`settings/settings_screen.dart`** | ❌ MISSING | **CREATE (see BLOCK 1.3)** |

---

## ⚙️ DAY 4 — Backend — Complete All API Gaps
> **Goal**: Every backend API endpoint must be fully implemented (no stubs), secure, and tested via Swagger.

---

### ⚙️ BLOCK 4.1 — Implement Token Blacklist (Logout Completion)
**File to Modify**: `Services/AuthService.cs`

Create a `RevokedTokens` table or reuse `Refreshtokens`:
```csharp
// In AuthService.cs - RevokeTokenAsync:
public async Task RevokeTokenAsync(int userId, string? refreshToken)
{
    if (!string.IsNullOrEmpty(refreshToken))
    {
        var token = await _context.Refreshtokens
            .FirstOrDefaultAsync(t => t.Token == refreshToken && t.UserId == userId);
        if (token != null)
        {
            token.IsRevoked = true;
            token.RevokedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }
}
```

---

### ⚙️ BLOCK 4.2 — Implement Admin Reports Endpoint
**File to Create**: `Controllers/ReportsController.cs`

Endpoints to implement:
```
GET /api/Reports/appointments-summary     → Monthly appointment counts
GET /api/Reports/user-growth              → New user registrations per week
GET /api/Reports/doctor-performance       → From DoctorPerformanceSummary view
GET /api/Reports/symptom-analysis         → Most common symptoms from Symptomchecks
GET /api/Reports/feedback-summary         → Average rating, feedback count
```

---

### ⚙️ BLOCK 4.3 — Implement Prescription View Endpoint for Students
**File to Modify**: `Controllers/AppointmentsController.cs`

Add endpoint:
```
GET /api/Appointments/{id}/prescription   → Returns prescription + medicines for an appointment
GET /api/Appointments/my-prescriptions   → All prescriptions for the current patient
```

The `Appointment` → `Prescription` → `PrescriptionMedicines` navigation chain must be `.Include()`d in the query.

---

### ⚙️ BLOCK 4.4 — Consolidate Reminder Controllers (Remove Duplicate)
**Files Involved**: `RemindersController.cs`, `MedicineRemindersController.cs`

**Action**:
1. Identify which endpoints the Flutter app actually calls (`medicine_reminder_service.dart`)
2. Keep `MedicineRemindersController.cs` as the canonical one
3. Add a `[Obsolete]` marker + 301 redirect to `RemindersController.cs` or **delete it entirely**
4. Add `[ApiExplorerSettings(IgnoreApi = true)]` if keeping for backward compat

---

### ⚙️ BLOCK 4.5 — Implement Real Cache Clearing
**File to Modify**: `AdminController.cs`, `Program.cs`

```csharp
// Program.cs - Register IMemoryCache:
builder.Services.AddMemoryCache();

// AdminController.cs - clear-cache:
[HttpPost("clear-cache")]
public IActionResult ClearCache([FromServices] IMemoryCache cache)
{
    if (cache is MemoryCache memCache)
    {
        memCache.Compact(1.0); // clears all entries
    }
    return Ok(new ApiResponse<object> { Success = true, Message = "Cache cleared" });
}
```

---

### ⚙️ BLOCK 4.6 — Implement Server-Side Notifications Push
**File to Modify**: `AppointmentsController.cs`

When a doctor changes appointment status (accepts/rejects/completes), insert a `Notification` record:
```csharp
// After saving appointment status update:
var notification = new Notification
{
    UserId = appointment.PatientId,
    Title = "Appointment Update",
    Message = $"Your appointment with Dr. {doctorName} has been {newStatus.ToLower()}.",
    Type = "appointment",
    RelatedEntityId = appointment.Id,
    RelatedEntityType = "Appointment",
    IsRead = false,
    CreatedAt = DateTime.UtcNow
};
_context.Notifications.Add(notification);
await _context.SaveChangesAsync();
```

This ensures when a student checks `/api/Notifications/unread`, they see real appointment updates.

---

### ⚙️ BLOCK 4.7 — Add Missing `GET /api/Appointments/my-prescriptions`
**File to Modify**: `AppointmentsController.cs`

```csharp
[HttpGet("my-prescriptions")]
[Authorize(Roles = "Student,Faculty")]
public async Task<IActionResult> GetMyPrescriptions()
{
    var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
    var prescriptions = await _context.Prescriptions
        .Include(p => p.Doctor).ThenInclude(d => d.User)
        .Include(p => p.Prescriptionmedicines)
        .Where(p => p.PatientId == userId)
        .OrderByDescending(p => p.CreatedAt)
        .ToListAsync();
    // Map and return...
}
```

---

### ⚙️ BLOCK 4.8 — Verify All Backend Endpoints via Swagger
**Action**: Systematically test every endpoint in Swagger locally:

| Controller | Endpoints to Test |
|---|---|
| Auth | register, verify-otp, login, current-user, forgot-password, reset-password, refresh-token, logout |
| Doctors | list, getById, search, dashboard, today-appointments, schedule CRUD, booking-settings |
| Appointments | book, list, status-update, cancel, prescription-add, my-prescriptions |
| Users | profile GET/PUT, change-password, upload-photo |
| Admin | statistics, users CRUD, toggle-status, system-settings, reports |
| AI | analyze (with test symptoms) |
| MedicalHistory | list, create, update, delete |
| MedicineReminders | list, create, update, delete, activate |
| EmergencyContacts | CRUD |
| Notifications | unread, mark-read, mark-all-read |
| Feedback | submit, list (admin) |

---

## ✅ DAY 5 — Testing, Polish & Production Deployment
> **Goal**: End-to-end full flow testing for each user role. Production configuration. Deployment verification.

---

### 🧪 BLOCK 5.1 — Full Flow Testing by Role

#### Student User Flow Test
```
1. Register as Student (BUITEMS email)
2. Receive OTP email → Verify OTP
3. Set password → Auto-login
4. View Student Dashboard → Stats load
5. Browse Doctors → Filter by specialty
6. Book Appointment → Select slot, confirm
7. View My Appointments → Upcoming tab
8. Use AI Symptom Checker → Enter symptoms, view result
9. Add Medicine Reminder → Verify local notification scheduled
10. Add Emergency Contact → CRUD
11. View Medical History → Add record
12. View My Prescriptions (new feature)
13. Check Notifications → Appointment update visible
14. Update Profile → Photo upload
15. Change Password → Re-login with new password
16. Logout → Routed to login, tokens cleared
```

#### Doctor User Flow Test
```
1. Admin creates Doctor account or use seeded data
2. Login as Doctor
3. View Doctor Dashboard → Appointment count
4. View Today's Appointments → List shows
5. Accept an Appointment → Status changes
6. View Patient Detail → Medical history visible
7. Write Prescription → Save prescription with medicines
8. View All Patients list
9. Manage Schedule → Set weekly availability
10. Set Booking Settings → Duration, advance days
11. Logout
```

#### Admin User Flow Test
```
1. Login as Admin
2. View Dashboard → All stats load (users, doctors, appointments)
3. Manage Users → Filter, search, toggle status, delete
4. Manage Doctors → View, edit doctor profiles
5. View Feedback → Feedback list
6. System Settings → Toggle maintenance mode (verify it saves)
7. View Reports → Charts load
8. Logout
```

---

### 🎨 BLOCK 5.2 — UI Polish & Error Handling Audit

For every screen, verify:
- [ ] Loading state (shimmer/spinner) shows while fetching
- [ ] Empty state (no data) shows correct message & icon
- [ ] Error state (network/server error) shows retry option
- [ ] Form validation messages are user-friendly (not technical)
- [ ] Success feedback (`SnackBar`/`AppFeedback`) shows on every mutation

**Key files to audit**:
- `lib/app/widgets/app_feedback.dart` — Ensure success/error/info snackbars look good
- All `_screen.dart` files — Check for `Obx(() => ...)` wrapping reactive data

---

### 🔧 BLOCK 5.3 — Android Boot Receiver (Medicine Reminders After Reboot)
**Files to Modify**: `android/app/src/main/AndroidManifest.xml`

Add boot receiver permission and receiver:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
  </intent-filter>
</receiver>
```

> This is built into `flutter_local_notifications` v17 — just needs manifest registration.

---

### 🚀 BLOCK 5.4 — Production Environment Configuration

#### Backend (Railway)
Verify these environment variables are set in Railway dashboard:
```
PORT                              → Set by Railway automatically
ASPNETCORE_ENVIRONMENT            → Production
ConnectionStrings__DefaultConnection → Railway MySQL URL
Jwt__Key                          → Your secure 32+ char key
Jwt__Issuer                       → MediAI-Backend
Jwt__Audience                     → MediAI-Users
Jwt__ExpiryInHours                → 24
EmailSettings__SmtpHost           → smtp.gmail.com
EmailSettings__SmtpPort           → 587
EmailSettings__SenderEmail        → mediaibuitems@gmail.com
EmailSettings__Username           → mediaibuitems@gmail.com
EmailSettings__Password           → [App Password]
EmailSettings__EnableSsl          → true
EmailSettings__UseConsoleForDevelopment → false
Gemini__ApiKey                    → [Your Gemini Key]
Gemini__Model                     → gemini-1.5-flash
CORS_ALLOWED_ORIGINS              → * (or your specific Flutter web domain)
```

#### Frontend (Production Build)
- Ensure `AppConfig.useLocalBackend = false` (default is false, so no action needed)
- Build APK: `flutter build apk --release`
- Build App Bundle: `flutter build appbundle --release`
- Verify app icon is set correctly (`flutter_launcher_icons` configured in `pubspec.yaml`)

---

### 🧪 BLOCK 5.5 — Final Production Verification Checklist

**Backend**:
- [ ] `GET https://mediaibackendrailway-production.up.railway.app/` → `{ "status": "Healthy" }`
- [ ] Swagger NOT accessible at `/swagger` in production (after Day 2 fix)
- [ ] Database migrations ran successfully (check Railway logs)
- [ ] HTTPS enforced (Railway handles this automatically)
- [ ] Email sending works (register a new user, check inbox)

**Frontend**:
- [ ] App points to production URL (default)
- [ ] Login works on physical device
- [ ] No console errors about missing controllers
- [ ] All images load (cached_network_image)
- [ ] Local notifications fire correctly for medicine reminders
- [ ] App handles "no internet" gracefully (shows error, not crash)

---

## 📊 Complete Module × Class Matrix

### Frontend — Every Module, Every Class

| Module | Screen | Controller | Binding | Status After Day 3 |
|---|---|---|---|---|
| **Auth** | | | | |
| splash | `splash_screen.dart` | `splash_controller.dart` | `splash_binding.dart` | ✅ Done |
| onboarding | `onboarding_screen.dart` | — | `_bindings.dart` | ✅ Done |
| register_email | `register_email_screen.dart` | `register_email_controller.dart` | `register_email_binding.dart` | ✅ Done (+ domain validation) |
| otp_verification | `otp_verification_screen.dart` | `otp_verification_controller.dart` | `otp_verification_binding.dart` | ✅ Done |
| set_password | `set_password_screen.dart` | `set_password_controller.dart` | `set_password_binding.dart` | ✅ Done |
| login | `login_screen.dart` | `login_controller.dart` | `login_binding.dart` | ✅ Done |
| forgot_password | `forgot_password_screen.dart` | `forgot_password_controller.dart` | `forgot_password_binding.dart` | ✅ Done |
| **Student** | | | | |
| dashboard | `student_dashboard_screen.dart` | `student_dashboard_controller.dart` | `student_dashboard_binding.dart` | ✅ Done |
| book_appointment | `book_appointment_screen.dart` | `book_appointment_controller.dart` | `book_appointment_binding.dart` | ✅ Done |
| my_appointments | `my_appointments_screen.dart` | `my_appointments_controller.dart` | `my_appointments_binding.dart` | ✅ Done |
| ai_symptom_checker | `ai_symptom_checker_screen.dart` | `ai_symptom_checker_controller.dart` | `ai_symptom_checker_binding.dart` | ✅ Done |
| medicine_reminders | `medicine_reminders_screen.dart` | (in screen) | `medicine_reminders_binding.dart` | ✅ Fixed |
| medical_history | `medical_history_screen.dart` | `medical_history_controller.dart` | `medical_history_binding.dart` | ✅ Done |
| emergency_contacts | `emergency_contacts_screen.dart` | `emergency_contacts_controller.dart` | `emergency_contacts_binding.dart` | ✅ Done |
| profile | `profile_screen.dart` | `profile_controller.dart` | `profile_binding.dart` | ✅ Done |
| **prescriptions** | `prescriptions_screen.dart` | `prescriptions_controller.dart` | `prescriptions_binding.dart` | 🆕 CREATE |
| **Doctor** | | | | |
| dashboard | `doctor_dashboard_screen.dart` | `doctor_dashboard_controller.dart` | `doctor_dashboard_binding.dart` | ✅ Done |
| today_appointments | `today_appointments_screen.dart` | `today_appointments_controller.dart` | `today_appointments_binding.dart` | ✅ Done |
| patient_detail | `patient_detail_screen.dart` | `patient_detail_controller.dart` | `patient_detail_binding.dart` | ✅ Done |
| write_prescription | `write_prescription_screen.dart` | `write_prescription_controller.dart` | `write_prescription_binding.dart` | ✅ Fixed |
| patients | `patients_screen.dart` | `patients_controller.dart` | `patients_binding.dart` | ✅ Done |
| schedule | `schedule_screen.dart` | `schedule_controller.dart` | `schedule_binding.dart` | ✅ Done |
| booking_settings | `booking_settings_screen.dart` | `booking_settings_controller.dart` | `booking_settings_binding.dart` | ✅ Done |
| **Admin** | | | | |
| dashboard | `admin_dashboard_screen.dart` | `admin_dashboard_controller.dart` | `admin_dashboard_binding.dart` | ✅ Done |
| manage_users | `manage_users_screen.dart` | — | — | ✅ Done |
| manage_doctors | `manage_doctors_screen.dart` | — | — | ✅ Done |
| manage_feedback | `manage_feedback_screen.dart` | `manage_feedback_controller.dart` | `manage_feedback_binding.dart` | ✅ Done |
| reports | `reports_screen.dart` | — | — | ✅ (after Day 4 backend) |
| system_settings | `system_settings_screen.dart` | — | — | ✅ Done |
| **Faculty** | | | | |
| dashboard | `faculty_dashboard_screen.dart` | `faculty_dashboard_controller.dart` | `faculty_dashboard_binding.dart` | ✅ Done |
| **Common** | | | | |
| notifications | `notifications_screen.dart` | `notifications_controller.dart` | `notifications_binding.dart` | ✅ Done |
| feedback | `feedback_screen.dart` | `feedback_controller.dart` | `feedback_binding.dart` | ✅ Done |
| appointment_detail | `appointment_detail_screen.dart` | — | — | ✅ Done |
| **settings** | `settings_screen.dart` | `settings_controller.dart` | `settings_binding.dart` | 🆕 CREATE |
| **Global Services** | | | | |
| — | — | `StorageService` | — | ✅ Done |
| — | — | `ApiService` | — | ✅ Done |
| — | — | `AuthService` | — | ✅ Fixed (URL prefix) |
| — | — | `NotificationService` | — | ✅ Done |
| — | — | `MedicineReminderService` | — | ✅ Done |
| — | — | `DoctorService` | — | ✅ Done |
| — | — | `AppointmentEventService` | — | ✅ Done |
| **Data Models** | | | | |
| — | `api_response.dart` | — | — | ✅ Done |
| — | `user.dart` | — | — | ✅ Done |
| — | `appointment.dart` | — | — | ✅ Done |
| — | `doctor.dart` | — | — | ✅ Done |
| — | `medicine_reminder.dart` | — | — | ✅ Done |
| — | `medical_history.dart` | — | — | ✅ Done |
| — | `emergency_contact.dart` | — | — | ✅ Done |
| — | `system_settings_model.dart` | — | — | ✅ Done |

---

### Backend — Every Controller, Service, Model

| Layer | File | Status After Day 4 |
|---|---|---|
| **Entry Point** | `Program.cs` | ✅ Fixed (Swagger gated, rate limiting added) |
| **Config** | `appsettings.json` | ✅ Fixed (secrets removed) |
| **Controllers** | | |
| | `AuthController.cs` | ✅ Done + logout revokes token |
| | `AiController.cs` | ✅ Done |
| | `AppointmentsController.cs` | ✅ Done + prescriptions for patient |
| | `DoctorsController.cs` | ✅ Done |
| | `UsersController.cs` | ✅ Done |
| | `AdminController.cs` | ✅ Fixed (real cache clear) |
| | `MedicalHistoryController.cs` | ✅ Done |
| | `MedicineRemindersController.cs` | ✅ Done (canonical) |
| | `RemindersController.cs` | 🗑️ DELETE or mark obsolete |
| | `EmergencyContactsController.cs` | ✅ Done |
| | `FeedbackController.cs` | ✅ Done |
| | `NotificationsController.cs` | ✅ Done |
| | `SymptomCheckerController.cs` | ✅ Done |
| | `FacultyController.cs` | ✅ Done |
| | **`ReportsController.cs`** | 🆕 CREATE |
| **Services** | | |
| | `AuthService.cs` | ✅ Fixed (token revocation) |
| | `IAuthService.cs` | ✅ Updated (RevokeTokenAsync) |
| | `EmailService.cs` | ✅ Done |
| | `IEmailService.cs` | ✅ Done |
| | `GeminiAiService.cs` | ✅ Done |
| | `IGeminiAiService.cs` | ✅ Done |
| | `UserService.cs` | ✅ Done |
| | `IUserService.cs` | ✅ Done |
| **Models** | | |
| | `MediaidbContext.cs` | ✅ Done |
| | `User.cs` | ✅ Done |
| | `Doctor.cs` | ✅ Done |
| | `Appointment.cs` | ✅ Done |
| | `Prescription.cs` | ✅ Done |
| | `Prescriptionmedicine.cs` | ✅ Done |
| | `Medicinereminder.cs` | ✅ Done |
| | `Medicalhistory.cs` | ✅ Done |
| | `Symptomcheck.cs` | ✅ Done |
| | `Notification.cs` | ✅ Done |
| | `Refreshtoken.cs` | ✅ Done |
| | `Emailverificationotp.cs` | ✅ Done |
| | `Emergencycontact.cs` | ✅ Done |
| | `Feedback.cs` | ✅ Done |
| | `Doctorreview.cs` | ✅ Done |
| | `Doctorschedule.cs` | ✅ Done |
| | `Auditlog.cs` | ✅ Done |
| | `Systemsetting.cs` | ✅ Done |
| **DTOs** | 25 files | ✅ All Done |
| **Middleware** | `GlobalExceptionMiddleware.cs` | ✅ Done |

---

## 📅 Daily Schedule Summary

| Day | Morning (4 hrs) | Afternoon (4 hrs) |
|---|---|---|
| **Day 1** | Fix auth URL bug (Block 1.1) + Fix all empty bindings (Block 1.2) | Create Settings screen (Block 1.3) + Remove all `print()` (Block 1.4) |
| **Day 2** | Remove secrets from code (Block 2.1) + Gate Swagger (Block 2.2) + Token revocation (Block 2.3) | Rate limiting (Block 2.4) + Email domain validation (Block 2.5) + Full auth flow test (Block 2.6) |
| **Day 3** | Auth + Student module review & fixes (Blocks 3.1–3.2) | Doctor + Admin + Faculty + Common modules (Blocks 3.3–3.6) + Create prescriptions screen |
| **Day 4** | Backend: Token blacklist + Reports controller + Prescription endpoint (Blocks 4.1–4.3) | Backend: Consolidate reminders + Cache + Notification push + Swagger testing (Blocks 4.4–4.8) |
| **Day 5** | Full flow testing by role (Block 5.1) + UI polish (Block 5.2) | Android boot receiver (Block 5.3) + Production config (Block 5.4) + Final checklist (Block 5.5) |

---

## 🚀 Recent Updates & Current State

1. **Streamlined Verification**: The identity/platform verification system has been completely removed to simplify user onboarding. The application now purely relies on robust **Email Verification** using MailKit.
2. **Profile Avatars**: Replaced complex camera-based photo uploads with standardized, static role-based avatar icons for Students, Faculty, Doctors, and Admins.
3. **Routing Bug Fix**: Resolved the double `/api` prefix bug in the frontend `auth_service.dart`, ensuring clean communication with the `.NET` backend endpoints.
4. **Binding Initialization**: All GetX `lazyPut()` bindings across major modules (Profile, Dashboards, Medical History) are successfully initialized and populated.

---

## ⚠️ Project Gaps & Remaining Work

Despite a solid foundation, several critical gaps must be addressed before the system is fully production-ready:

### 1. Admin Module Completeness
- **Frontend Hardcoded Data**: The Admin Reports UI (`reports_screen.dart`) is currently populated with static, hardcoded dummy data (e.g., `totalAppointments: 245`).
- **Backend Mock Endpoints**: `AdminController.cs` contains mock endpoints for `clear-cache` and `backup-database` that simply return simulated success messages instead of performing actual server operations.
- **Action Required**: Create real statistical aggregation endpoints in the backend and wire up the Flutter UI to fetch live data.

### 2. Security & Environment Configuration
- **Plaintext Secrets**: The backend `appsettings.json` file currently exposes plaintext credentials, specifically the Gmail App Password (`tvoaqogpimqtmrrr`). 
- **Action Required**: Migrate sensitive secrets from `appsettings.json` into Environment Variables or a secure Secrets Manager, especially before pushing to any public repository or deploying to production.

### 3. Appointment & Notification Edge Cases
- **Declined Appointment Notifications**: Ensure robust bidirectional notification logic exists when a Doctor declines an appointment (the system currently handles Confirmations well, but cancellation notification coverage needs a thorough review).

---

> **Last Updated**: June 20, 2026
> **Status**: In Progress — Completing Remaining Gaps
> **Project**: BUITEMS Medi-AI FYP 2025–2026
