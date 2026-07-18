# Doctor Dashboard — Complete Technical Reference

> **Source Files**: `lib/app/modules/doctor/` and `Medi_AI_Backend_railway/Backend-APIs/Controllers/DoctorsController.cs`

---

## 1. Module Overview

The Doctor Dashboard is the clinical management interface for BUITEMS clinic doctors. It provides tools for managing today's appointments, viewing patient records, writing prescriptions, managing their weekly schedule, setting booking preferences, and logging leave periods.

**State Management**: GetX (`GetView<DoctorDashboardController>`)
**Main Entry Route**: `/doctor-dashboard`
**Controller Location**: `lib/app/modules/doctor/dashboard/doctor_dashboard_controller.dart`
**Service Layer**: `lib/app/services/doctor_service.dart` (dedicated service — unlike student which uses ApiService directly)

---

## 2. Screen Inventory

| Screen | Route | File | State |
|---|---|---|---|
| Dashboard | `/doctor-dashboard` | `dashboard/doctor_dashboard_screen.dart` | `DoctorDashboardController` |
| Today Appointments | `/doctor/today-appointments` | `today_appointments/` | — |
| Patients | `/doctor/patients` | `patients/` | — |
| Patient Detail | `/doctor/patient-detail` | `patient_detail/patient_detail_screen.dart` | StatelessWidget |
| Schedule | `/doctor/schedule` | `schedule/` | — |
| Leaves | `/doctor/leaves` | `leaves/` | — |
| Booking Settings | `/doctor/booking-settings` | `booking_settings/booking_settings_screen.dart` | `BookingSettingsController` |
| Write Prescription | `/doctor/write-prescription` | `write_prescription/write_prescription_screen.dart` | StatefulWidget |
| Profile | `/doctor/profile` | `profile/` | — |
| Settings | `/settings` | `common/settings/` (shared) | `SettingsController` |
| Notifications | `/notifications` | `common/notifications/` (shared) | `AppNotificationsController` |

---

## 3. Sidebar / Drawer

**Trigger**: Hamburger icon in AppBar.
**Header**: `UserAccountsDrawerHeader` — doctor avatar, "Dr. {name}", email.
**Gradient**: `AppTheme.primary` → `AppTheme.primaryDark`

| # | Icon | Label | Action |
|---|---|---|---|
| 1 | `dashboard_outlined` | Dashboard | `Get.back()` |
| 2 | `today` | Today's Appointments | `controller.goToTodayAppointments()` |
| 3 | `people_outline` | My Patients | `controller.goToPatients()` |
| 4 | `schedule_outlined` | My Schedule | `controller.goToSchedule()` |
| 5 | `beach_access_outlined` | My Leaves | `controller.goToLeaves()` |
| 6 | `settings_applications` | Booking Settings | `controller.goToBookingSettings()` |
| — | Divider | — | — |
| 7 | `person_outline` | Profile | `controller.goToProfile()` |
| 8 | `settings_outlined` | Settings | `controller.goToSettings()` |
| — | Divider (footer) | — | — |
| 9 | `logout` (red) | Logout | `controller.logout()` |

---

## 4. Screen-by-Screen UI Breakdown

### 4.1 Doctor Dashboard Screen
**File**: `dashboard/doctor_dashboard_screen.dart`

#### AppBar
- Leading: Hamburger menu → Drawer
- Title: "Doctor Dashboard"
- Action: `Badge` notification icon with `unreadNotifications.length` count → `/notifications`

#### Body Sections

1. **Welcome Card** — Shows "Dr. {name}" + department + specialization. Gradient banner.
2. **Statistics Grid** — 3 tappable cards:
   - "Total Today" (`totalPatientsToday`) — tapping clears filter (show all)
   - "Pending" (`pendingToday`) — tapping sets `activeFilter = 'pending'`
   - "Completed" (`completedToday`) — tapping sets `activeFilter = 'completed'`
3. **Quick Actions** — 5 buttons in a `Wrap`: Today's Appointments, Patients, Schedule, Leaves, Booking Settings.
4. **Today's Appointments** — filterable list. Each card shows:
   - Patient name, time slot, status chip
   - **Action buttons** based on status:
     - `Pending` → "Confirm" button → `PUT /api/appointments/{id}/status` with `Status="Confirmed"`
     - `Confirmed` → "Mark Checked" button → `PUT /api/appointments/{id}/status` with `Status="Checked"`
     - "Write Prescription" button → navigates to `WritePrescriptionScreen` with `{ patientName, appointmentId }`
     - "View Patient" button → navigates to `PatientDetailScreen` with full patient args
5. **Upcoming Appointments** — max 2 items, same card style.

#### Controller State (DoctorDashboardController)

| Observable | Type | Description |
|---|---|---|
| `currentUser` | `Rx<User?>` | From `AuthService.getCurrentUser()` |
| `_allTodayAppointments` | `RxList<Appointment>` | All appointments for today |
| `todayAppointments` | `List<Appointment>` (computed) | Filtered by `activeFilter` value |
| `upcomingAppointments` | `RxList<Appointment>` | Future appointments |
| `activeFilter` | `RxString` | `''`=all, `'pending'`=pending+confirmed, `'completed'`=completed+checked |
| `isLoading` | `RxBool` | Dashboard load state |
| `totalPatientsToday` | `RxInt` | `_allTodayAppointments.length` |
| `completedToday` | `RxInt` | Filtered count |
| `pendingToday` | `RxInt` | Filtered count |
| `unreadNotifications` | `RxList<Map>` | Raw notification objects |

**Polling**: `_startNotificationPolling()` creates a `Timer.periodic` at 30-second intervals that:
1. Calls `_checkForNewAppointments()` — scans for appointments created after `_lastCheckTime`
2. Calls `_loadUnreadNotifications(showPopups: true)` — fetches notifications and shows local push if new

**Event subscription**: Listens to `AppointmentEventService` stream. On any appointment event → immediately refreshes `loadUpcomingAppointments()` and `loadTodayAppointments()`.

**Auto-create doctor profile** (`EnsureDoctorProfileExists`):
When a user with `Role="Doctor"` first accesses any DoctorsController endpoint, if no row exists in `doctors` table for their `userId`, the backend automatically creates a default profile row:
```csharp
doctor = new Doctor {
    Specialization = "General Physician",
    LicenseNumber = $"TEMP-{user.Id}-{DateTime.UtcNow.Ticks}",
    Qualification = "MBBS",
    Experience = 5,
    IsAvailable = true,
    ...
};
```

### 4.2 Patient Detail Screen
**File**: `patient_detail/patient_detail_screen.dart` (495 lines)

Opened by passing a Map of patient data via `Get.arguments`. StatelessWidget.

| Section | Fields Shown |
|---|---|
| Patient Header | CircleAvatar (initial letter), name (bold), subtitle (CMS number + department) |
| Personal Information | CMS Number, Exact Age (calculated from DOB), Gender, Date of Birth, Phone, Email |
| Medical History | `FutureBuilder` → `GET /api/MedicalHistory/patient/{id}` — shows conditions list or "No records" |
| Emergency Contacts | `FutureBuilder` → `GET /api/EmergencyContacts/user/{id}` — shows contacts list or "No contacts" |
| Action Buttons | "Write Prescription" (outlined, primary), "View Appointments" (outlined) |

Age is calculated precisely using year/month/day arithmetic, not just birth year subtraction.

### 4.3 Booking Settings Screen
**File**: `booking_settings/booking_settings_screen.dart` (381 lines)

#### AppBar
- "Appointment Booking Settings"
- No actions

#### Sections

**Section 1 — Appointment Configuration** (`Icons.calendar_today`):
- `Slider` (15–60, divisions: 9): Appointment Duration in minutes
- `Slider` (1–50): Max Patients Per Day
- `SwitchListTile`: Auto Confirm Appointments — if enabled, all new appointments are Confirmed regardless of role

**Section 2 — Break Time Configuration** (`Icons.lunch_dining`):
- `SwitchListTile`: Enable Break Time
- If enabled: two time picker rows — Break Start Time, Break End Time

**Section 3 — Reminder & Notification Settings** (`Icons.notifications`):
- `SwitchListTile`: Enable Appointment Reminders
- `Slider` (5–120 min, divisions: 23): Reminder Notification Time (minutes before appointment)

**Save Button**: Full-width `ElevatedButton` → `controller.saveSettings()` → `PUT /api/doctors/my-booking-settings`

**Storage**: Settings are serialized to JSON and stored in the `systemsettings` table with key `DoctorBookingSettings:{doctorId}`. Example value:
```json
{"appointmentDuration":30,"maxPatientsPerDay":20,"autoConfirmAppointments":false,"enableBreakTime":true,"breakStartTime":"12:00","breakEndTime":"13:00","enableAppointmentReminders":true,"reminderNotificationMinutes":30}
```

### 4.4 Write Prescription Screen
**File**: `write_prescription/write_prescription_screen.dart` (396 lines)

StatefulWidget (not GetX). Opens with `Get.arguments = { patientName, appointmentId }`.

#### AppBar
- Leading: BUITEMS logo image (falls back to back arrow if image fails)
- Title: "Write Prescription"

#### Form Sections
1. **Patient Header Card** — shows `Icons.person` + patient name (from args)
2. **Diagnosis Field** — `TextFormField` (required, validates non-empty)
3. **Notes Field** — multi-line `TextFormField` for general notes
4. **Medications List** — dynamic list. Each row:
   - Medicine Name (TextFormField)
   - Dosage (TextFormField)
   - Frequency dropdown (Once/Twice/Thrice daily)
   - Duration (TextFormField)
   - Instructions (TextFormField)
   - Delete row button (`Icons.remove_circle`)
5. **"Add Medication" Button** — `TextButton.icon` with `Icons.add` → adds blank row to `_medications` list
6. **Submit Button** — `ElevatedButton`: "Save Prescription" → calls `DoctorService.writePrescription()` → `POST /api/Prescriptions`

### 4.5 Schedule Screen
**File**: `schedule/`

Shows Mon–Sun day cards. Each day:
- Day name label
- Active toggle (`SwitchListTile`)
- If active: Start Time picker + End Time picker

"Save Schedule" button → `POST /api/doctors/schedule`

### 4.6 Leaves Screen
**File**: `leaves/`

| UI Element | Detail |
|---|---|
| FAB (+) | Opens Add Leave bottom sheet |
| Leave cards | Date range (start → end), reason text, delete `IconButton` |
| Add bottom sheet | Start date picker, end date picker, reason text field, Submit button |

`POST /api/doctors/leaves` to add. `DELETE /api/doctors/leaves/{id}` to remove.

### 4.7 Patients Screen
**File**: `patients/`

List of unique patients who have had appointments with the doctor. Each card:
- Avatar (initial letter)
- Patient name
- Role (Student/Faculty)
- Last visit date

Tap → navigates to `PatientDetailScreen` with full patient args.

Source: `GET /api/doctors/patients`

### 4.8 Profile Screen
**File**: `profile/`

Editable fields: Full Name, Phone Number, Specialization, Room Number, Bio, Availability toggle.
Save → `PUT /api/doctors/profile`

---

## 5. API Endpoints Reference

| Method | Route | Auth | Purpose | Request Body | Key Notes |
|---|---|---|---|---|---|
| `GET` | `/api/doctors/profile` | JWT (Doctor) | Get own doctor profile | — | Auto-creates profile if missing (`EnsureDoctorProfileExists`) |
| `PUT` | `/api/doctors/profile` | JWT (Doctor) | Update own profile | `{ fullName, phoneNumber, specialization, roomNumber, bio, isAvailable }` | — |
| `GET` | `/api/doctors` | AllowAnonymous | All doctors list | — | Used by students for booking |
| `GET` | `/api/doctors/{id}` | AllowAnonymous | Single doctor with schedules + reviews | — | — |
| `GET` | `/api/doctors/specialization/{spec}` | AllowAnonymous | Doctors by specialization | — | Case-insensitive contains match |
| `PATCH` | `/api/doctors/{id}/availability` | JWT (Doctor/Admin) | Toggle availability | `bool` | — |
| `PUT` | `/api/doctors/{id}` | JWT (Doctor/Admin) | Admin-level doctor update | `Doctor` model | — |
| `GET` | `/api/doctors/appointments/today` | JWT (Doctor) | Today's appointments | — | `DayOfWeek` filtered by today |
| `GET` | `/api/doctors/appointments/upcoming` | JWT (Doctor) | Future appointments | — | — |
| `GET` | `/api/doctors/appointments` | JWT (Doctor) | All doctor appointments | — | — |
| `GET` | `/api/doctors/patients` | JWT (Doctor) | All unique patients | — | Distinct by PatientId |
| `GET` | `/api/doctors/statistics` | JWT (Doctor) | Stats (today/completed/pending/total) | — | — |
| `GET` | `/api/doctors/schedule` | JWT (Doctor) | Doctor's weekly schedule | — | — |
| `POST` | `/api/doctors/schedule` | JWT (Doctor) | Update weekly schedule | `List<ScheduleDto>` | Replaces existing rows |
| `GET` | `/api/doctors/leaves` | JWT (Doctor) | Doctor's leave list | — | — |
| `POST` | `/api/doctors/leaves` | JWT (Doctor) | Add leave period | `{ startDate, endDate, reason }` | — |
| `DELETE` | `/api/doctors/leaves/{id}` | JWT (Doctor) | Delete leave | — | — |
| `GET` | `/api/doctors/my-booking-settings` | JWT (Doctor) | Load booking settings | — | Reads from `systemsettings` table |
| `PUT` | `/api/doctors/my-booking-settings` | JWT (Doctor) | Save booking settings | `BookingSettingsDto` | Writes to `systemsettings` table |
| `PUT` | `/api/appointments/{id}/status` | JWT (Doctor) | Change appointment status | `{ status: "Confirmed"/"Checked"/"Cancelled" }` | Primary way doctor updates appointments |
| `POST` | `/api/Prescriptions` | JWT (Doctor) | Write prescription | `{ appointmentId, patientId, diagnosis, notes, medications }` | — |
| `GET` | `/api/MedicalHistory/patient/{id}` | JWT (Doctor) | Patient's medical history | — | Shown in PatientDetail screen |
| `GET` | `/api/EmergencyContacts/user/{id}` | JWT | Patient's emergency contacts | — | Shown in PatientDetail screen |
| `GET` | `/api/Notifications/unread` | JWT | Doctor's unread notifications | — | Polled every 30 seconds |
| `PUT` | `/api/Notifications/{id}/read` | JWT | Mark one notification read | — | — |

---

## 6. Database Tables Reference

| Table | Key Columns | Role in Doctor Dashboard |
|---|---|---|
| `users` | `Id`, `FullName`, `Role="Doctor"`, `Email`, `PhoneNumber` | Doctor identity; linked to `doctors` table via `UserId` |
| `doctors` | `Id`, `UserId` (FK→users), `Specialization`, `LicenseNumber`, `Qualification`, `Experience`, `RoomNumber`, `Bio`, `IsAvailable`, `AverageRating`, `TotalRatings` | Doctor profile data; auto-created if missing |
| `appointments` | `Id`, `PatientId`, `DoctorId`, `AppointmentDate`, `AppointmentTime`, `Duration`, `Status`, `Symptoms`, `Notes` | Core of Today/Upcoming Appointments; status updated via PUT endpoint |
| `doctorschedules` | `Id`, `DoctorId`, `DayOfWeek`, `StartTime`, `EndTime`, `IsActive` | Doctor Schedule screen; also used by booking validation |
| `doctorleaves` | `Id`, `DoctorId`, `StartDate`, `EndDate`, `Reason`, `CreatedAt` | Doctor Leaves screen; checked during appointment booking |
| `prescriptions` | `Id`, `AppointmentId`, `PatientId`, `DoctorId`, `Diagnosis`, `Notes`, `Medications` (JSON), `CreatedAt` | Written via Write Prescription screen |
| `medicalhistory` | `Id`, `UserId`, `Condition`, `Notes`, `RecordedDate` | Shown read-only in Patient Detail screen |
| `emergencycontacts` | `Id`, `UserId`, `ContactName`, `Relationship`, `PhoneNumber` | Shown read-only in Patient Detail screen |
| `systemsettings` | `Id`, `SettingKey`, `SettingValue` | Stores booking config as `DoctorBookingSettings:{doctorId}` JSON key |
| `notifications` | `Id`, `UserId`, `Title`, `Message`, `Type`, `IsRead`, `CreatedAt` | Polled every 30s; shown in NotificationsScreen |

---

## 7. Gaps & Known Issues

| # | Issue | File | Impact |
|---|---|---|---|
| 1 | 30-second polling for notifications | `doctor_dashboard_controller.dart` lines 84–96 | Not scalable; will cause unnecessary server load with many doctors |
| 2 | `WritePrescriptionScreen` is StatefulWidget, not GetX | `write_prescription_screen.dart` | Inconsistent pattern; form state not restored on navigation pop |
| 3 | Booking settings stored as JSON string in `systemsettings` | `DoctorsController.cs` | No schema validation; malformed JSON causes silent failures |
| 4 | Auto-create doctor profile uses temp license number | `DoctorsController.cs` lines 50–51 | License `TEMP-{id}-{ticks}` is not a real license; should require admin setup |
| 5 | AI Symptom Analyzer not available to doctors | Doctor module | Doctors cannot use the diagnostic tool themselves |
| 6 | No delete appointment endpoint shown in doctor UI | Doctor dashboard | Doctor can only change status; cannot remove an appointment row |
