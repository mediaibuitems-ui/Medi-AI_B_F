# Student Dashboard — Complete Technical Reference

> **Source Files**: `lib/app/modules/student/` and `Medi_AI_Backend_railway/Backend-APIs/Controllers/`

---

## 1. Module Overview

The Student dashboard is the primary interface for BUITEMS students. It gives them access to appointment booking, AI symptom checking, medicine reminders, medical history tracking, emergency contacts, and their profile.

**State Management**: GetX (`GetView<StudentDashboardController>`)
**Main Entry Route**: `/student-dashboard`
**Controller Location**: `lib/app/modules/student/dashboard/student_dashboard_controller.dart`

---

## 2. Screen Inventory

| Screen | Route | File | Controller |
|---|---|---|---|
| Dashboard | `/student-dashboard` | `dashboard/student_dashboard_screen.dart` | `StudentDashboardController` |
| Book Appointment | `/book-appointment` | `book_appointment/book_appointment_screen.dart` | `BookAppointmentController` |
| My Appointments | `/my-appointments` | `my_appointments/my_appointments_screen.dart` | `MyAppointmentsController` |
| AI Symptom Analyzer (Input) | `/ai-symptom-input` | `symptom_analyzer/ai_symptom_input_screen.dart` | `AiSymptomInputController` |
| AI Symptom Result | `/ai-symptom-result` | `symptom_analyzer/ai_symptom_result_screen.dart` | `AiSymptomResultController` |
| Medicine Reminders | `/medicine-reminders` | `medicine_reminders/medicine_reminders_screen.dart` | StatefulWidget (no GetX controller) |
| Medical History | `/medical-history` | `medical_history/` | — |
| Emergency Contacts | `/emergency-contacts` | `emergency_contacts/` | — |
| Profile | `/profile` | `profile/` | — |
| Prescription History | `/prescription-history` | `prescription_history/` | — |
| Notifications | `/notifications` | `common/notifications/` | `AppNotificationsController` (shared) |
| Feedback | `/feedback` | `common/feedback/` | `FeedbackController` (shared) |
| Settings | `/settings` | `common/settings/` | `SettingsController` (shared) |

---

## 3. Sidebar / Drawer

**Trigger**: Hamburger icon (`Icons.menu`) in AppBar leading position.
**Header**: `UserAccountsDrawerHeader` — shows user avatar (NetworkImage from `profileImage` URL or fallback `Icons.school_rounded`), full name, email.
**Gradient**: `AppTheme.primary` → `AppTheme.primaryDark`

| # | Icon | Label | Action |
|---|---|---|---|
| 1 | `dashboard_outlined` | Dashboard | `Get.back()` (close drawer) |
| 2 | `calendar_month_outlined` | Book Appointment | `controller.goToBookAppointment()` |
| 3 | `calendar_today_outlined` | My Appointments | `controller.goToMyAppointments()` |
| 4 | `psychology_outlined` | AI Symptom Analyzer | `controller.goToAIChecker()` |
| 5 | `alarm_outlined` | Medicine Reminders | `controller.goToMedicineReminders()` |
| 6 | `history_edu` | Medical History | `controller.goToMedicalHistory()` |
| 7 | `contact_phone_outlined` | Emergency Contacts | `controller.goToEmergencyContacts()` |
| — | Divider | — | — |
| 8 | `person_outline` | Profile | `controller.goToProfile()` |
| 9 | `feedback_outlined` | Feedback | `controller.goToFeedback()` |
| 10 | `settings_outlined` | Settings | `controller.goToSettings()` |
| — | Divider (footer) | — | — |
| 11 | `logout` (red) | Logout | `controller.logout()` |

---

## 4. Screen-by-Screen UI Breakdown

### 4.1 Dashboard Screen
**File**: `dashboard/student_dashboard_screen.dart` (832 lines)

#### AppBar
- Leading: Hamburger menu (`Icons.menu`, white) → opens Drawer
- Title: "Student Dashboard"
- Background: `AppTheme.primary`
- Action: `Badge` notification icon → `Get.toNamed(AppRoutes.notifications)` (badge count = `controller.unreadNotifications.value`)

#### Body Sections (top to bottom)
1. **Loading State** — `Obx` shows `CircularProgressIndicator` + "Loading your health data..." if `isLoading.value == true` OR user ID is missing
2. **Welcome Card** (`_buildWelcomeCard`) — gradient banner, circular avatar, greeting text, name, department. Tapping the card navigates to Profile.
3. **Statistics Cards** (`_buildStatisticsCards`) — Row of 3 `DashboardStatCard` widgets: Total Appointments / Completed / Upcoming
4. **Quick Actions** (`_buildQuickActions`) — 5 `DashboardQuickAction` buttons: Book Appointment, My Appointments, AI Analyzer, Medicine Reminders, Medical History
5. **Upcoming Appointments** (`_buildUpcomingAppointments`) — Shows up to 3 upcoming appointments from `controller.upcomingAppointments`. Each card shows: doctor name, date/time, status chip. "View All" link → My Appointments.

#### Controller State (StudentDashboardController)
| Observable | Type | Description |
|---|---|---|
| `isLoading` | `RxBool` | True during initial data load |
| `upcomingAppointments` | `RxList<Appointment>` | From `/appointments/student/{id}/upcoming` |
| `recentAppointments` | `RxList<Appointment>` | Last 30 days from `/appointments/student/{id}/history` |
| `currentUser` | `Rx<User?>` | Loaded via `AuthService.getCurrentUser()` |
| `totalAppointments` | `RxInt` | upcoming + recent count |
| `completedAppointments` | `RxInt` | Filtered from recent where status=Completed |
| `upcomingCount` | `RxInt` | `upcomingAppointments.length` |
| `unreadNotifications` | `RxInt` | Count from `/notifications/unread` |

`loadDashboardData()` runs three parallel calls via `Future.wait`:
1. `_loadUpcomingAppointments()` → `GET /appointments/student/{id}/upcoming`
2. `_loadRecentAppointments()` → `GET /appointments/student/{id}/history`
3. `_loadUnreadNotifications()` → `GET /notifications/unread`

### 4.2 Book Appointment Screen
**File**: `book_appointment/book_appointment_screen.dart` (292 lines)

| UI Element | Detail |
|---|---|
| AppBar | "Book Appointment", primary color |
| Specialization Dropdown | `DropdownButtonFormField<String>` — "All specializations" + list of unique specializations from doctor list |
| Doctor Selection | Radio-style `Card` list of filtered doctors. Each card: avatar (first letter), name, specialization, room number, rating |
| Date Picker | `TextFormField` with `Icons.calendar_today` → `showDatePicker()` (Monday–Friday only) |
| Time Slot Grid | Dynamic `GridView` of available time slots generated from doctor schedule and booking settings duration |
| Reason / Symptoms Field | Multi-line `TextFormField` |
| Submit Button | "Book Appointment" — validates form, calls `controller.bookAppointment()` |

**Booking Validation (enforced by backend `AppointmentsController.cs`)**:
- Only Mon–Fri (university working days)
- Only 08:00–17:00
- Slot must align with doctor's schedule `StartTime` + slot duration interval
- Slot must not fall in doctor's break time (if enabled)
- Slot must not already be booked
- Doctor must not be on leave for selected date
- Doctor must not be at max patients per day

### 4.3 My Appointments Screen
**File**: `my_appointments/my_appointments_screen.dart` (81 lines)

| UI Element | Detail |
|---|---|
| AppBar | "My Appointments" |
| Body | `Obx` → loading / error / empty / list state |
| Each card | `ListTile`: doctor avatar (calendar icon), doctor name, date/time string (formatted `MMM dd, yyyy - hh:mm a`), status text (colored: green=confirmed, orange=pending, red=cancelled) |

### 4.4 AI Symptom Analyzer (Input) Screen
**File**: `symptom_analyzer/ai_symptom_input_screen.dart` (181 lines)

| UI Element | Detail |
|---|---|
| AppBar | "AI Symptom Analyzer", history `IconButton` (placeholder) |
| Warning Banner | Orange-bordered container: "This tool provides general guidance, not medical advice." |
| Section 1 | "Select Your Symptoms" — `Wrap` of `FilterChip` widgets (30+ common symptoms). Selected chips turn blue. `toggleSymptom()` adds/removes from `selectedSymptoms` list. |
| Section 2 | "Additional Symptoms" — plain `TextField` for free-text symptoms |
| Section 3 | "Severity" — `DropdownButtonFormField`: Mild / Moderate / Severe |
| Section 4 | "Duration" — `DropdownButtonFormField`: Less than a day / 1-2 days / 3-7 days / More than a week |
| Submit Button | "Analyze Symptoms" — `ElevatedButton` → calls `controller.analyzeSymptoms()` |
| Loading overlay | Translucent overlay + `CircularProgressIndicator` while API call is in flight |

### 4.5 AI Symptom Result Screen
**File**: `symptom_analyzer/ai_symptom_result_screen.dart`

Shows the parsed `SymptomAnalyzerResponseDto` returned by `POST /api/analyzer/evaluate`:
- Possible Condition (large text)
- Confidence Level percentage
- Severity badge (Mild=green / Moderate=orange / Severe=red)
- Urgency Message
- Recommendations (bulleted list)
- Home Care Guidance (bulleted list)
- Recommended Doctor Type
- "Book Appointment" `ElevatedButton` → navigates to Book Appointment with pre-filled specialization

### 4.6 Medicine Reminders Screen
**File**: `medicine_reminders/medicine_reminders_screen.dart` (697 lines)

This screen is a `StatefulWidget` (no GetX controller). It uses `SharedPreferences` for offline-first storage and syncs with backend.

| UI Element | Detail |
|---|---|
| AppBar | "Medicine Reminders" |
| FAB (+) | Opens Add Reminder bottom sheet |
| Loading | `CircularProgressIndicator` while `isLoading == true` |
| Reminder card list | Each card: medicine name, dosage, frequency, next reminder time, enabled toggle (`Switch`), edit (`Icons.edit`), delete (`Icons.delete`) |
| Add/Edit bottom sheet | Fields: Medicine Name, Dosage, Frequency (Once/Twice/Thrice daily), Time picker, Days of week selector |
| Delete confirmation | `showDialog` with Confirm/Cancel |

**Offline-first architecture**:
- Loads from `SharedPreferences` key `offline_medicine_reminders_{userId}` first (instant display)
- Then syncs with backend `GET /MedicineReminders` and updates local cache
- On create/update/delete: persists to local cache first, then calls backend API

### 4.7 Medical History Screen
Shows user's recorded medical conditions. Each entry: condition name, notes, date recorded. FAB to add new entry.

### 4.8 Emergency Contacts Screen
Shows emergency contacts for the user. Each contact: name, relationship, phone number. FAB to add. Edit and delete per contact.

### 4.9 Profile Screen
Editable profile: avatar (tap to upload), Full Name, Email, Phone, Date of Birth, Gender dropdown, Department, Registration Number. "Save" button calls `PUT /api/Users/profile`.

### 4.10 Prescription History Screen
List of prescriptions written by doctors. Each entry: doctor name, diagnosis, medications list, date. Read-only view.

---

## 5. API Endpoints Reference

| Method | Route | Auth | Purpose | Request Body | Response |
|---|---|---|---|---|---|
| `GET` | `/api/appointments/student/{id}/upcoming` | JWT | Upcoming appointments for student | — | `List<AppointmentResponseDto>` |
| `GET` | `/api/appointments/student/{id}/history` | JWT | Past appointments (paginated, page/limit query params) | — | `{ totalCount, items: List<AppointmentResponseDto> }` |
| `GET` | `/api/appointments/my-appointments` | JWT | All appointments for current user | — | `List<AppointmentResponseDto>` |
| `POST` | `/api/appointments` | JWT | Book new appointment | `{ doctorId, dateTime, symptoms, notes }` | `AppointmentResponseDto` |
| `DELETE` | `/api/appointments/{id}` | JWT | Cancel appointment | — | Success message |
| `GET` | `/api/doctors` | AllowAnonymous | All doctors list | — | `List<DoctorDto>` |
| `GET` | `/api/doctors/{id}` | AllowAnonymous | Single doctor with schedule/reviews | — | `DoctorDto` with schedules array |
| `GET` | `/api/doctors/specialization/{spec}` | AllowAnonymous | Doctors by specialization | — | `List<DoctorDto>` |
| `POST` | `/api/analyzer/evaluate` | JWT | AI symptom analysis | `{ selectedSymptoms, otherSymptoms, severity, duration }` | `SymptomAnalyzerResponseDto` |
| `GET` | `/api/MedicineReminders` | JWT | All reminders for current user | — | `List<ReminderDto>` |
| `POST` | `/api/MedicineReminders` | JWT | Add reminder | `{ medicineName, dosage, frequency, reminderTime, daysOfWeek }` | `ReminderDto` |
| `PUT` | `/api/MedicineReminders/{id}` | JWT | Update reminder | Partial reminder fields | `ReminderDto` |
| `DELETE` | `/api/MedicineReminders/{id}` | JWT | Delete reminder | — | Success message |
| `GET` | `/api/MedicalHistory` | JWT | Medical history for current user | — | `List<HistoryDto>` |
| `POST` | `/api/MedicalHistory` | JWT | Add history entry | `{ condition, notes, recordedDate }` | `HistoryDto` |
| `PUT` | `/api/MedicalHistory/{id}` | JWT | Update history entry | — | `HistoryDto` |
| `DELETE` | `/api/MedicalHistory/{id}` | JWT | Delete history entry | — | Success message |
| `GET` | `/api/EmergencyContacts` | JWT | Emergency contacts for current user | — | `List<ContactDto>` |
| `POST` | `/api/EmergencyContacts` | JWT | Add contact | `{ contactName, relationship, phoneNumber }` | `ContactDto` |
| `PUT` | `/api/EmergencyContacts/{id}` | JWT | Update contact | — | `ContactDto` |
| `DELETE` | `/api/EmergencyContacts/{id}` | JWT | Delete contact | — | Success message |
| `GET` | `/api/Prescriptions/patient/{id}` | JWT | Prescriptions written for patient | — | `List<PrescriptionDto>` |
| `GET` | `/api/Users/profile` | JWT | Current user profile | — | `UserDto` |
| `PUT` | `/api/Users/profile` | JWT | Update profile | `{ fullName, phoneNumber, ... }` | `UserDto` |
| `GET` | `/api/Notifications/unread` | JWT | Unread notifications for user | — | `List<NotificationDto>` |
| `PUT` | `/api/Notifications/{id}/read` | JWT | Mark notification as read | — | Success |
| `PUT` | `/api/Notifications/mark-all-read` | JWT | Mark all read | — | Success |

---

## 6. Database Tables Reference

| Table | Key Columns | Role in Student Dashboard |
|---|---|---|
| `users` | `Id`, `FullName`, `Email`, `Role`, `Department`, `RegistrationNumber`, `DateOfBirth`, `Gender`, `ProfileImageUrl` | Source of all profile data shown on Welcome Card and Profile screen |
| `appointments` | `Id`, `PatientId` (FK→users), `DoctorId` (FK→doctors), `AppointmentDate`, `AppointmentTime`, `Duration`, `Status`, `Symptoms`, `Notes`, `CreatedAt` | Core of all appointment screens. `Status` values: Pending / Confirmed / Completed / Cancelled / Checked |
| `doctors` | `Id`, `UserId` (FK→users), `Specialization`, `LicenseNumber`, `RoomNumber`, `Bio`, `IsAvailable`, `AverageRating` | Displayed in Book Appointment doctor selection cards |
| `doctorschedules` | `Id`, `DoctorId`, `DayOfWeek`, `StartTime`, `EndTime`, `IsActive` | Used by appointment booking slot validation |
| `doctorleaves` | `Id`, `DoctorId`, `StartDate`, `EndDate`, `Reason` | Backend checks during booking — blocks slot if doctor is on leave |
| `prescriptions` | `Id`, `AppointmentId`, `PatientId`, `DoctorId`, `Diagnosis`, `Notes`, `CreatedAt` | Displayed in Prescription History screen |
| `medicinereminders` | `Id`, `UserId`, `MedicineName`, `Dosage`, `Frequency`, `ReminderTime`, `DaysOfWeek`, `IsActive` | Synced from/to backend; local cache in SharedPreferences |
| `medicalhistory` | `Id`, `UserId`, `Condition`, `Notes`, `RecordedDate`, `CreatedAt` | CRUD managed by Medical History screen |
| `emergencycontacts` | `Id`, `UserId`, `ContactName`, `Relationship`, `PhoneNumber`, `CreatedAt` | CRUD managed by Emergency Contacts screen |
| `notifications` | `Id`, `UserId`, `Title`, `Message`, `Type`, `IsRead`, `CreatedAt` | Shown in Notifications screen; badge count in AppBar |

---

## 7. Gaps & Known Issues

| # | Issue | File | Impact |
|---|---|---|---|
| 1 | AI symptom history button is a no-op | `ai_symptom_input_screen.dart` line 18 | History icon tapped does nothing |
| 2 | Medicine Reminders offline cache uses `SharedPreferences` only | `medicine_reminders_screen.dart` | Sync loop risk if backend and local diverge |
| 3 | My Appointments has no cancel button | `my_appointments_screen.dart` | Student cannot cancel from this screen; must contact admin |
| 4 | No real-time updates | Student dashboard | Appointments from doctor only appear after manual pull-to-refresh |
| 5 | Book Appointment time slots not dynamically fetched | `book_appointment_controller.dart` | Slot grid is generated client-side; backend validates on submit |
