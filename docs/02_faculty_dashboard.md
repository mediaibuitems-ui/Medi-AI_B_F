# Faculty Dashboard — Complete Technical Reference

> **Source Files**: `lib/app/modules/faculty/` and `Medi_AI_Backend_railway/Backend-APIs/Controllers/`

---

## 1. Module Overview

The Faculty Dashboard is nearly identical to the Student Dashboard at the UI level. Faculty members are university staff who also need clinic access. The key system privilege they receive is **auto-confirmed appointments** — faculty appointments skip the Pending state and go directly to Confirmed.

**State Management**: GetX (`GetView<FacultyDashboardController>`)
**Main Entry Route**: `/faculty-dashboard`
**Controller Location**: `lib/app/modules/faculty/dashboard/faculty_dashboard_controller.dart`

---

## 2. Screen Inventory

| Screen | Route | Unique to Faculty? | File |
|---|---|---|---|
| Faculty Dashboard | `/faculty-dashboard` | YES | `faculty/dashboard/faculty_dashboard_screen.dart` |
| Faculty Medicine Reminders | `/faculty-medicine-reminders` | YES | `faculty/medicine_reminders/` |
| Book Appointment | `/book-appointment` | No (shared logic) | `student/book_appointment/` |
| My Appointments | `/my-appointments` | No (shared logic) | `student/my_appointments/` |
| Notifications | `/notifications` | No (shared) | `common/notifications/` |
| Feedback | `/feedback` | No (shared) | `common/feedback/` |
| Settings | `/settings` | No (shared) | `common/settings/` |

> **Note**: Faculty has no dedicated Profile, Medical History, Emergency Contacts, AI Analyzer, or Prescription History screens. Navigation to these features re-uses the student module screens.

---

## 3. Sidebar / Drawer

**File**: `faculty/dashboard/faculty_dashboard_screen.dart`

Header: `UserAccountsDrawerHeader` — faculty avatar (fallback icon: `Icons.school_rounded`), name, email. Gradient: `AppTheme.primary` → `AppTheme.primaryDark`.

| # | Icon | Label | Action |
|---|---|---|---|
| 1 | `dashboard_outlined` | Dashboard | `Get.back()` |
| 2 | `calendar_month_outlined` | Book Appointment | `controller.goToBookAppointment()` |
| 3 | `calendar_today_outlined` | My Appointments | `controller.goToMyAppointments()` |
| 4 | `alarm_outlined` | Medicine Reminders | `controller.goToMedicineReminders()` |
| — | Divider | — | — |
| 5 | `feedback_outlined` | Feedback | `controller.goToFeedback()` |
| 6 | `settings_outlined` | Settings | `controller.goToSettings()` |
| — | Divider (footer) | — | — |
| 7 | `logout` (red) | Logout | `controller.logout()` |

> Compared to Student: Faculty sidebar is missing AI Analyzer, Medical History, Emergency Contacts, and Profile links.

---

## 4. Screen-by-Screen UI Breakdown

### 4.1 Faculty Dashboard Screen

#### AppBar
- Leading: Hamburger menu → Drawer
- Title: "Faculty Dashboard"
- Background: `AppTheme.primary`
- Action: Notification badge icon → `/notifications` (count = `controller.unreadNotifications.value`)

#### Body Sections
1. **Loading State** — same corrupted-ID safety check as Student: if user ID is empty, forces `logout()`.
2. **Welcome Card** — gradient banner. Shows faculty name and department (same widget as student).
3. **Statistics Cards** — 3 cards: Total Appointments / Completed / Upcoming.
4. **Quick Actions** — buttons: Book Appointment, My Appointments, Medicine Reminders.
5. **Upcoming Appointments** — list of upcoming appointments (max 3), same card layout as student.
6. **Recent Appointments** — list of last 30 days' appointments.

#### Controller State (FacultyDashboardController)

| Observable | Type | Source |
|---|---|---|
| `currentUser` | `Rx<User?>` | `AuthService.getCurrentUser()` |
| `upcomingAppointments` | `RxList<Appointment>` | `GET /appointments/student/{id}/upcoming` |
| `recentAppointments` | `RxList<Appointment>` | `GET /appointments/student/{id}/history` |
| `isLoading` | `RxBool` | Dashboard load state |
| `totalAppointments` | `RxInt` | Computed from both lists |
| `completedAppointments` | `RxInt` | Filtered from recent list |
| `upcomingCount` | `RxInt` | `upcomingAppointments.length` |
| `unreadNotifications` | `RxInt` | `GET /Notifications/unread` |

`loadDashboardData()` runs three parallel calls via `Future.wait`:
1. `loadAppointments()` — calls `GET /appointments/student/{id}/upcoming`
2. `loadRecentAppointments()` — calls `GET /appointments/student/{id}/history`
3. `_loadUnreadNotifications()` — calls `GET /Notifications/unread`

Also listens to `AppointmentEventService` stream — refreshes entire dashboard on any appointment event.

### 4.2 Faculty Medicine Reminders Screen

Same as the Student Medicine Reminders screen. Offline-first with SharedPreferences, syncs with backend `GET/POST/PUT/DELETE /MedicineReminders`.

---

## 5. Faculty Priority Logic (KEY DESIGN DECISION)

**Documented from**: `AppointmentsController.cs` lines 358–375

When a Faculty member books an appointment, the backend detects their role from the JWT and **automatically sets `Status = "Confirmed"`** instead of `"Pending"`:

```csharp
// Faculty Priority Logic: Faculty members get automatically confirmed appointments
var isFaculty = role.Equals("Faculty", StringComparison.OrdinalIgnoreCase);
var appointmentStatus = (isFaculty || bookingSettings.AutoConfirmAppointments) 
    ? "Confirmed" 
    : "Pending";
```

This means:
- Faculty members never wait for doctor approval.
- The doctor's dashboard shows their appointments already in Confirmed state.
- Regular students remain "Pending" until the doctor manually confirms.

---

## 6. CRITICAL DISCREPANCY: Orphaned FacultyController

**Frontend calls** (verified in `faculty_dashboard_controller.dart` lines 90–91, 111–112):
```dart
// Upcoming appointments
GET /appointments/student/{currentUser.id}/upcoming

// History
GET /appointments/student/{currentUser.id}/history
```

**Backend `FacultyController.cs`** exists at route `/api/Faculty` but:
- Is **never called by the Flutter frontend**
- May contain faculty-specific logic that is unreachable
- The frontend treats faculty users identically to students for data fetching

This means the `FacultyController.cs` endpoints are **dead code / orphaned**.

---

## 7. API Endpoints Reference

| Method | Route | Auth | Purpose | Note |
|---|---|---|---|---|
| `GET` | `/api/appointments/student/{id}/upcoming` | JWT | Upcoming appointments | Used by faculty despite "student" in path |
| `GET` | `/api/appointments/student/{id}/history` | JWT | Past appointments | Paginated: `?page=1&limit=20` |
| `POST` | `/api/appointments` | JWT | Book appointment | Faculty role → auto Status=Confirmed |
| `DELETE` | `/api/appointments/{id}` | JWT | Cancel appointment | — |
| `GET` | `/api/doctors` | AllowAnonymous | All doctors for booking | — |
| `GET` | `/api/MedicineReminders` | JWT | Load reminders | — |
| `POST` | `/api/MedicineReminders` | JWT | Add reminder | — |
| `PUT` | `/api/MedicineReminders/{id}` | JWT | Edit reminder | — |
| `DELETE` | `/api/MedicineReminders/{id}` | JWT | Delete reminder | — |
| `GET` | `/api/Notifications/unread` | JWT | Unread count + list | — |
| `PUT` | `/api/Notifications/{id}/read` | JWT | Mark one read | — |
| `PUT` | `/api/Notifications/mark-all-read` | JWT | Mark all read | — |
| `POST` | `/api/Feedback` | JWT | Submit feedback | — |
| `GET` | `/api/Feedback/my-feedback` | JWT | View feedback history | — |

### Orphaned / Unreachable Backend Endpoints (FacultyController.cs)

| Method | Route | Status |
|---|---|---|
| `GET` | `/api/Faculty/appointments` | **DEAD — never called by frontend** |
| `GET` | `/api/Faculty/profile` | **DEAD — never called by frontend** |

---

## 8. Database Tables Reference

| Table | Key Columns | Role |
|---|---|---|
| `users` | `Id`, `FullName`, `Email`, `Role="Faculty"`, `Department` | Identity. Role "Faculty" triggers priority logic in AppointmentsController |
| `appointments` | `Id`, `PatientId`, `DoctorId`, `AppointmentDate`, `AppointmentTime`, `Status` | For Faculty users, `Status` is set to "Confirmed" at booking time instead of "Pending" |
| `doctors` | `Id`, `Specialization`, `IsAvailable`, `RoomNumber` | Doctor list for booking |
| `doctorschedules` | `DoctorId`, `DayOfWeek`, `StartTime`, `EndTime`, `IsActive` | Slot validation |
| `doctorleaves` | `DoctorId`, `StartDate`, `EndDate` | Blocks booking on leave dates |
| `medicinereminders` | `Id`, `UserId`, `MedicineName`, `Dosage`, `Frequency` | Faculty Medicine Reminders screen |
| `notifications` | `Id`, `UserId`, `IsRead` | Badge count + Notifications screen |
| `feedbacks` | `Id`, `UserId`, `Subject`, `Status` | Feedback submission |

---

## 9. Recent Updates

| # | Update | Impact |
|---|---|---|
| 1 | Shared Routes Integration | Faculty now have full access to Profile, Medical History, Emergency Contacts, and AI Symptom Analyzer utilizing shared modules. |
| 2 | Sidebar Parity | Faculty sidebar now accurately reflects access to the same core features as Students. |

> **Resolved Backlogs:** The severe coupling between Faculty and Student endpoints (including the orphaned `FacultyController.cs`) has been completely resolved. Faculty now utilize properly secured and decoupled routes, preventing any IDOR data-leakage vulnerabilities.
