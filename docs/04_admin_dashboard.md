# Admin Dashboard — Complete Technical Reference

> **Source Files**: `lib/app/modules/admin/` and `Medi_AI_Backend_railway/Backend-APIs/Controllers/AdminController.cs`

---

## 1. Module Overview

The Admin Dashboard is the master control panel for the entire Medi-AI system. It provides system-wide statistics, user management (create/edit/suspend/delete), doctor management, appointment oversight, feedback response, manual user verification, report generation, and global system configuration.

**State Management**: GetX (`GetView<AdminDashboardController>`)
**Main Entry Route**: `/admin-dashboard`
**Controller Location**: `lib/app/modules/admin/dashboard/admin_dashboard_controller.dart`
**Auth Guard**: `[Authorize(Roles = "admin,Admin")]` on `AdminController.cs`

---

## 2. Screen Inventory

| Screen | Route | File | State |
|---|---|---|---|
| Dashboard | `/admin-dashboard` | `dashboard/admin_dashboard_screen.dart` | `AdminDashboardController` |
| Manage Users | `/admin/manage-users` | `manage_users/manage_users_screen.dart` | `ManageUsersController` |
| Manage Doctors | `/admin/manage-doctors` | `manage_doctors/` | `ManageDoctorsController` |
| Doctor Leaves | `/admin/doctor-leaves` | `doctor_leaves/` | `AdminDoctorLeavesController` |
| Verifications | `/admin/verifications` | `verifications/` | `VerificationsController` |
| Appointments | `/admin/appointments` | `appointments/` | `AdminAppointmentsController` |
| Reports | `/admin/reports` | `reports/reports_screen.dart` | StatefulWidget |
| Manage Feedback | `/admin/manage-feedback` | `manage_feedback/manage_feedback_screen.dart` | `ManageFeedbackController` |
| System Settings | `/admin/system-settings` | `system_settings/system_settings_screen.dart` | `SystemSettingsController` |
| Notifications | `/notifications` | `common/notifications/` (shared) | `AppNotificationsController` |

---

## 3. Sidebar / Drawer

**File**: `dashboard/admin_dashboard_screen.dart`

Header: `UserAccountsDrawerHeader` — admin avatar, "System Administrator" label, admin email.
**Gradient**: `AppTheme.primary` → `AppTheme.primaryDark`

| # | Icon | Label | Action |
|---|---|---|---|
| 1 | `dashboard_outlined` | Dashboard | `Get.back()` |
| 2 | `people_outline` | Manage Users | → `/admin/manage-users` |
| 3 | `medical_services_outlined` | Manage Doctors | → `/admin/manage-doctors` |
| 4 | `calendar_today_outlined` | Appointments | → `/admin/appointments` |
| 5 | `verified_user_outlined` | Verifications | → `/admin/verifications` |
| 6 | `feedback_outlined` | Manage Feedback | → `/admin/manage-feedback` |
| 7 | `beach_access_outlined` | Doctor Leaves | → `/admin/doctor-leaves` |
| 8 | `bar_chart` | Reports | → `/admin/reports` |
| — | Divider | — | — |
| 9 | `settings_outlined` | System Settings | → `/admin/system-settings` |
| — | Divider (footer) | — | — |
| 10 | `logout` (red) | Logout | `controller.logout()` |

---

## 4. Screen-by-Screen UI Breakdown

### 4.1 Admin Dashboard Screen
**File**: `dashboard/admin_dashboard_screen.dart`

#### AppBar
- Leading: Hamburger menu → Drawer
- Title: "Admin Dashboard"
- Background: `AppTheme.primary`
- Action: `Badge` icon — badge label = `controller.systemAlerts.value` (count of system alert notifications). Tapping opens `showDialog` listing system alerts.

#### Body Sections

1. **Welcome Card** — gradient banner: "System Administrator" label.

2. **Statistics Grid** — 2 rows × 3 cards:
   - Row 1: Total Users / Total Students / Total Faculty
   - Row 2: Total Doctors / Total Appointments / Pending Verifications
   - All values from `GET /api/Admin/dashboard-stats`

3. **Trends Charts** (fl_chart integration):
   - Bar chart 1: "Appointments (Last 6 Months)" — `controller.monthlyTrends` data
   - Bar chart 2: "New Registrations (Last 6 Months)" — `controller.monthlyUserTrends` data

4. **Quick Actions** — `Wrap` of 6 navigation buttons:
   - Manage Users / Manage Doctors / Reports / Verifications / System Settings / Manage Feedback

5. **Recent Activity** — last 4 `auditlogs` entries. Each entry:
   - Icon (determined by `Action.Contains("register")`, `"appointment"`, etc.)
   - Action text
   - Timestamp

6. **System Overview** — summary card:
   - Today's Appointments count
   - Pending Verifications count
   - System Alerts count

#### Controller State (AdminDashboardController)

| Observable | Type | Source |
|---|---|---|
| `totalUsers` | `RxInt` | `dashboard-stats` response |
| `totalStudents` | `RxInt` | `dashboard-stats` response |
| `totalFaculty` | `RxInt` | `dashboard-stats` response |
| `totalDoctors` | `RxInt` | `dashboard-stats` response |
| `totalAppointments` | `RxInt` | `dashboard-stats` response |
| `pendingVerifications` | `RxInt` | `dashboard-stats` response |
| `monthlyTrends` | `RxList<Map>` | 6-month appointment data |
| `monthlyUserTrends` | `RxList<Map>` | 6-month registration data |
| `recentActivities` | `RxList<Map>` | Top 4 audit log entries |
| `recentUsers` | `RxList<Map>` | Newest 4 users |
| `notifications` | `RxList<Map>` | Admin-targeted notifications |
| `systemAlerts` | `RxInt` | Count of system alert type notifications |

`loadDashboardData()` calls four parallel methods via `Future.wait`:
1. `loadStatistics()` → `GET /api/Admin/dashboard-stats`
2. `loadRecentActivities()` → `GET /api/Admin/recent-activities`
3. `loadRecentUsers()` → `GET /api/Admin/recent-users`
4. `loadNotifications()` → `GET /api/Admin/notifications`

---

### 4.2 Manage Users Screen
**File**: `manage_users/manage_users_screen.dart` (364 lines)

#### AppBar
- Title: "Manage Users" (transparent background, centered)
- No actions

#### Buttons & Controls

| Element | Detail |
|---|---|
| FAB (bottom-right) | `+` icon, `AppTheme.primary` → opens `UserFormDialog` for creating a new user |
| Search Bar | `TextField` with `Icons.search`, `controller.searchController`, updates on `onChanged` → `controller.updateSearch()` |
| Role Filter Chips | Horizontal scroll row: All / Student / Doctor / Faculty / Admin — `FilterChip` per role, calls `controller.setFilter(label)` |
| User List | `RefreshIndicator` > infinite-scroll `ListView.builder` with `controller.scrollController`. Last item shows loading spinner if `isLoadingMore.value` |

#### Per-User Card

Each card shows:
- `CircleAvatar` (first letter of name, `AppTheme.primary`)
- Full name (bold)
- `"Role • email"` subtitle (grey)
- **Emergency Contacts button** (`Icons.contact_phone`) → `_showEmergencyContactsDialog()` — opens AlertDialog with `FutureBuilder` loading that user's contacts via `controller.fetchUserEmergencyContacts(userId)`
- **Toggle Status button** — `Icons.check_circle` (green, active) or `Icons.cancel` (grey, inactive) → `controller.toggleUserStatus(id)` → `PATCH /api/Admin/users/{id}/toggle-status`
- **Delete button** (`Icons.delete`, red) → `_confirmDelete()` → shows dialog → `controller.deleteUser(id)` → `DELETE /api/Admin/users/{id}`

Tap card → opens `UserFormDialog` pre-filled with user data for editing → `controller.updateUser(id, data)` → `PUT /api/Admin/users/{id}`

#### UserFormDialog
Modal dialog with fields: Full Name, Email, Role dropdown, Department, Phone.
Submit creates or updates the user.

---

### 4.3 Manage Feedback Screen
**File**: `manage_feedback/manage_feedback_screen.dart` (330 lines)

#### AppBar
- Title: "Manage Feedback"

#### Body
`RefreshIndicator` > `ListView.separated` of feedback cards.

| Status | Card Color | Border | Behavior |
|---|---|---|---|
| Pending | `warning.withOpacity(0.05)` | `warning.withOpacity(0.18)` | Tappable → opens respond sheet |
| Responded | `primary.withOpacity(0.05)` | `primary.withOpacity(0.18)` | Read-only (no tap) |

Each card shows:
- CircleAvatar with user's first letter (primary color)
- User name + role badge
- Subject (bold)
- Message text
- Timestamp
- Status chip

**Respond Bottom Sheet** (opens on tap of Pending card):
- Large `TextField` (multi-line) for admin response text
- `ElevatedButton`: "Send Response" → `controller.respondToFeedback(id, text)` → `PUT /api/Feedback/admin/{id}/respond`
- Backend: sets `feedback.AdminResponse = responseText`, `feedback.Status = "Responded"`, `feedback.RespondedAt = DateTime.UtcNow`, and creates a `Notification` for the feedback author.

---

### 4.4 System Settings Screen
**File**: `system_settings/system_settings_screen.dart` (313 lines)

#### AppBar
- Title: "System Settings"
- Action 1: `Icons.refresh` → `controller.loadSettings()`
- Action 2: `Icons.save` → `controller.saveSettings()` → `PUT /api/Admin/system-settings`

#### Sections

**General Settings**:
- `TextField`: System Name (`controller.systemNameController`)
- `TextField`: Admin Email (`controller.emailController`)
- `TextField`: Support Email (`controller.supportEmailController`)

**Security Settings**:
- `SwitchListTile`: "Require email verification"
- `SwitchListTile`: "Two-factor authentication" (UI only — 2FA not actually implemented in backend)
- `DropdownButton<int>`: "Session timeout" — options: 15 / 30 / 60 / 120 minutes
- `ListTile` + embedded dropdown: "Max login attempts"

**Notification Settings** (third section):
- `SwitchListTile`: "Enable email notifications"
- `SwitchListTile`: "Enable SMS notifications" (UI only — no SMS service in backend)
- `SwitchListTile`: "Auto-approve new registrations"

**Action Buttons** (bottom of screen):

| Button | Color | Action |
|---|---|---|
| "Save Settings" | Primary | `controller.saveSettings()` → `PUT /api/Admin/system-settings` |
| "Clear Cache" | Orange | Confirm dialog → `POST /api/Admin/clear-cache` (calls `IMemoryCache.Compact(1.0)`) |
| "Backup Database" | Blue | Confirm dialog → `POST /api/Admin/backup-database` (returns fake success — no actual dump) |

---

### 4.5 Reports Screen
**File**: `reports/reports_screen.dart` (672 lines)

StatefulWidget. Reuses `GET /api/Admin/dashboard-stats` for live data.

| UI Element | Detail |
|---|---|
| Period Selector | Horizontal chip row: Today / This Week / This Month / This Year / Custom |
| Stats Cards | Total / Completed / Cancelled / Pending appointments + Total / New / Active users |
| Bar Chart 1 | Monthly appointment trends (`fl_chart`) |
| Bar Chart 2 | Monthly user registration trends (`fl_chart`) |
| Generate Report Dialog | `DropdownButtonFormField` for period, report type selector, "Generate" button — shows `SnackBar` confirmation |
| Recent Reports List | Hardcoded 3 items: Monthly appointments report, User registration report, Doctor performance report |
| Download Button | Web only (`kIsWeb`) — uses `download_helper_web.dart` to trigger browser download. On mobile: shows "Download is only available on web" snackbar. |

> **Gap**: `recentReports` list is hardcoded static data, not fetched from backend.

---

### 4.6 Verifications Screen
List of users where `IsEmailVerified == false || IsActive == false`. Each row shows user name, email, role, and a "Verify" button.

Verify button → `PUT /api/Admin/verify-user/{userId}` → sets `IsEmailVerified = true` and `IsActive = true`.

> **Gap**: No pagination. Fetches all unverified users at once.

---

### 4.7 Admin Appointments Screen
Global read-only view of all appointments across all doctors and patients.
Source: `GET /api/appointments` (Admin only).

Shows: patient name, doctor name, date/time, status, symptoms. No edit controls.

---

### 4.8 Manage Doctors Screen
**File**: `manage_doctors/`

Similar to Manage Users but specifically for Doctor records. Shows specialization, license number, room number.
Admin can edit doctor profiles and toggle doctor availability.
Source: `GET /api/doctors` + `PUT /api/doctors/{id}` + `PATCH /api/doctors/{id}/availability`.

---

### 4.9 Doctor Leaves Screen (Admin View)
Global admin view of all doctor leave records across all doctors.
Source: `GET /api/Admin/doctor-leaves` (or `GET /api/doctors/leaves` with admin token).
Admin can delete any leave record.

---

## 5. API Endpoints Reference

### Admin Controller (`/api/Admin`)

| Method | Route | Auth | Purpose | Request Body | Response Data |
|---|---|---|---|---|---|
| `GET` | `/api/Admin/dashboard-stats` | Admin | Aggregated stats + 6-month trends | — | `{ totalUsers, totalStudents, totalFaculty, totalDoctors, totalAppointments, pendingVerifications, completedAppointments, cancelledAppointments, monthlyTrends[], monthlyUserTrends[] }` |
| `GET` | `/api/Admin/recent-activities` | Admin | Top 5 audit log entries | — | `List<AuditLogDto>` |
| `GET` | `/api/Admin/recent-users` | Admin | 5 newest user registrations | — | `List<UserDto>` |
| `GET` | `/api/Admin/notifications` | Admin | Admin-role notifications | — | `List<NotificationDto>` |
| `GET` | `/api/Admin/users` | Admin | Paginated + searchable user list | `?page=1&limit=10&search=...&role=...` | `{ totalCount, users[] }` |
| `POST` | `/api/Admin/users` | Admin | Create user | `{ fullName, email, password, role, ... }` | `UserDto`. If role=Doctor, auto-creates `doctors` row. |
| `PUT` | `/api/Admin/users/{id}` | Admin | Update user | `{ fullName, email, role, ... }` | `UserDto` |
| `DELETE` | `/api/Admin/users/{id}` | Admin | Delete user | — | Success message |
| `PATCH` | `/api/Admin/users/{id}/toggle-status` | Admin | Suspend/activate user | — | `{ isActive }`. Side effect: sets `IsEmailVerified=false` if suspending. |
| `GET` | `/api/Admin/pending-verifications` | Admin | Unverified users | — | `List<UserDto>` (all, no pagination) |
| `PUT` | `/api/Admin/verify-user/{userId}` | Admin | Approve user | — | Sets `IsEmailVerified=true`, `IsActive=true` |
| `GET` | `/api/Admin/system-settings` | Admin | Load all settings | — | `{ maintenanceMode, enableEmailNotifications, sessionTimeoutMinutes, ... }` |
| `PUT` | `/api/Admin/system-settings` | Admin | Save settings | `SystemSettingsDto` | Success message. Upserts each KV pair into `systemsettings` table. |
| `POST` | `/api/Admin/clear-cache` | Admin | Clear server RAM cache | — | Calls `IMemoryCache.Compact(1.0)` |
| `POST` | `/api/Admin/backup-database` | Admin | Trigger DB backup | — | **FAKE** — returns simulated backup ID, no actual dump |
| `GET` | `/api/Admin/doctor-leaves` | Admin | All doctor leaves | — | `List<DoctorLeaveDto>` |

### Other Endpoints Used by Admin Screens

| Method | Route | Purpose |
|---|---|---|
| `GET` | `/api/appointments` | All appointments (admin global view) |
| `GET` | `/api/doctors` | All doctors list (Manage Doctors screen) |
| `PUT` | `/api/doctors/{id}` | Edit doctor (Manage Doctors screen) |
| `PATCH` | `/api/doctors/{id}/availability` | Toggle doctor availability |
| `GET` | `/api/Feedback/admin/all` | All feedback for admin review |
| `PUT` | `/api/Feedback/admin/{id}/respond` | Admin responds to feedback |
| `GET` | `/api/EmergencyContacts/user/{userId}` | View user's emergency contacts in dialog |

---

## 6. Dashboard Stats Deep Dive

**File**: `AdminController.cs` lines 125–228 (approx.)

`GetDashboardStats()` runs **14 separate `CountAsync()` queries** sequentially against MySQL:

```csharp
totalUsers = await _context.Users.CountAsync()
totalStudents = await _context.Users.CountAsync(u => u.Role == "Student")
totalFaculty = await _context.Users.CountAsync(u => u.Role == "Faculty")
totalDoctors = await _context.Users.CountAsync(u => u.Role == "Doctor")
totalAppointments = await _context.Appointments.CountAsync()
completedAppointments = await _context.Appointments.CountAsync(a => a.Status == "Completed")
cancelledAppointments = await _context.Appointments.CountAsync(a => a.Status == "Cancelled")
pendingAppointments = await _context.Appointments.CountAsync(a => a.Status == "Pending")
// ... + pending verifications, today's count, etc.
```

Monthly trends calculated by iterating backwards from current month and using `GroupBy(Month, Year)`.

---

## 7. Database Tables Reference

| Table | Key Columns | Role in Admin Dashboard |
|---|---|---|
| `users` | `Id`, `FullName`, `Email`, `Role`, `IsActive`, `IsEmailVerified`, `CreatedAt` | Primary target of Manage Users CRUD + Verifications screen |
| `doctors` | `Id`, `UserId`, `Specialization`, `LicenseNumber`, `RoomNumber`, `IsAvailable` | Manage Doctors screen; auto-created when admin adds Doctor-role user |
| `appointments` | `Id`, `PatientId`, `DoctorId`, `Status`, `AppointmentDate` | All Appointments screen; counted in dashboard stats |
| `feedbacks` | `Id`, `UserId`, `Subject`, `Message`, `AdminResponse`, `Status`, `RespondedAt` | Manage Feedback screen; admin responds here |
| `auditlogs` | `Id`, `UserId`, `Action`, `EntityType`, `CreatedAt` | Recent Activity list on dashboard |
| `systemsettings` | `Id`, `SettingKey`, `SettingValue` | System Settings screen — KV pairs upserted by `PUT /system-settings` |
| `doctorleaves` | `Id`, `DoctorId`, `StartDate`, `EndDate`, `Reason` | Doctor Leaves admin global view |
| `notifications` | `Id`, `UserId`, `Title`, `Message`, `Type`, `IsRead` | System alerts badge on AppBar; admin notifications list |

---

## 8. System Settings — Key-Value Architecture

The backend `UpsertSetting()` method handles each setting as a KV pair:
```csharp
// PUT /api/Admin/system-settings
private async Task UpsertSetting(string key, string value) {
    var existing = await _context.Systemsettings.FirstOrDefaultAsync(s => s.SettingKey == key);
    if (existing != null) existing.SettingValue = value;
    else _context.Systemsettings.Add(new Systemsetting { SettingKey = key, SettingValue = value });
}
```

Known setting keys:
| SettingKey | SettingValue Type | Used By |
|---|---|---|
| `MaintenanceMode` | `"true"/"false"` | Global maintenance toggle |
| `EnableEmailNotifications` | `"true"/"false"` | Notification service |
| `EnableSmsNotifications` | `"true"/"false"` | SMS service (unimplemented) |
| `SessionTimeoutMinutes` | `"30"` | Session management |
| `RequireEmailVerification` | `"true"/"false"` | Auth flow |
| `DoctorBookingSettings:{id}` | JSON string | Per-doctor booking config (set by doctor, not admin) |

---

## 9. Gaps & Known Issues

| # | Issue | File | Impact |
|---|---|---|---|
| 1 | 14 sequential COUNT queries in dashboard-stats | `AdminController.cs` | High DB latency; scales poorly. Should use a single aggregated query or caching. |
| 2 | DB Backup is fake | `AdminController.cs` | Admin believes backup occurred but nothing is stored anywhere. |
| 3 | Reports recentReports list is hardcoded | `reports_screen.dart` lines 75–94 | Displayed dates (2024-11-25 etc.) are static strings, not real report records. |
| 4 | No pagination on pending-verifications | `AdminController.cs` | All unverified users fetched at once — crash risk at scale. |
| 5 | 2FA toggle is UI-only | `system_settings_screen.dart` | Switch does nothing on the backend; no 2FA system implemented. |
| 6 | SMS notifications toggle is UI-only | `system_settings_screen.dart` | No SMS service integrated in backend. |
| 7 | Toggle-status side effect undocumented in UI | `AdminController.cs` | Suspending a user also forces `IsEmailVerified=false` — not shown in the UI. |
| 8 | Audit log icon resolution is string-matching | `AdminController.cs` | Brittle: `Action.Contains("register")` → icon mapping breaks if action string changes. |
