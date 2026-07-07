# Architectural and Stability Audit of Medi-AI
## System Overview
Medi-AI is a Flutter and ASP.NET Core-based healthcare guidance and appointment system. This document provides a comprehensive, role-by-role architectural breakdown, explicitly focusing on the mapping of Frontend, Backend, and Database components, alongside a critical assessment of stability gaps and crash risks.

---

## 1. Student Architecture, Gaps & Crash Risks

### Frontend (Flutter) Architecture
*   **Dashboard Module (`lib/app/modules/student/dashboard/`)**:
    *   **Controller**: `StudentDashboardController` handles state for appointments, notifications, and navigation. Uses `Future.wait()` for parallel loading of initial data (`loadAppointments`, `loadRecentAppointments`, `_loadUnreadNotifications`).
    *   **Screen**: `StudentDashboardScreen` contains the primary UI layout, a Drawer for navigation, `DashboardStatCard` elements for quick stats, and list views for upcoming appointments.
    *   **Key Buttons/Actions**:
        *   "Book Appointment" -> routes to `AppRoutes.bookAppointment`.
        *   "AI Health Analyzer" -> routes to `AppRoutes.symptomAnalyzerInput`.
        *   "My Appointments" -> routes to `AppRoutes.myAppointments`.
*   **AI Symptom Analyzer (`lib/app/modules/student/symptom_analyzer/`)**:
    *   **Screen**: `AiSymptomResultScreen` displays the analysis result. Uses a `SingleChildScrollView` wrapping nested cards and `ListView.builder` elements for recommendations and home care guidance.

### Frontend Stability & Crash Risks
*   **Corrupted State Crash Loop**: In `StudentDashboardController.loadDashboardData`, if `user.id.isEmpty`, the app forces an auto-logout. However, if the local session state is corrupt but the ID check passes, subsequent API calls to `/Appointments/student/{id}/upcoming` can fail silently or cause UI inconsistency.
*   **RenderFlex Overflows**: In `AiSymptomResultScreen`, the use of `shrinkWrap: true` inside a `SingleChildScrollView` can cause performance hitches and potential rendering overflows on smaller devices if the AI returns excessively long recommendations. The UI lacks `Flexible` or `Expanded` safeguards in some nested rows.
*   **Missing Loading/Disabled States**: Action buttons, such as "Book an Appointment", do not consistently implement disabled states while background processes (like GetX routing or API requests) are executing, allowing rapid double-tapping that pushes duplicate routes to the stack.
*   **Unbounded Lists**: The Dashboard loads appointments using `ListView.separated` inside a `Column`. While currently limited to 3 items on the dashboard, the "View All" screens lack pagination logic in both the GetX controllers and ScrollControllers, risking memory exhaustion if a student has hundreds of historical appointments.

### Backend (ASP.NET Core) Architecture
*   **Controllers**:
    *   `AppointmentsController.cs`: Handles `GET /Appointments/student/{id}/upcoming` and `GET /Appointments/student/{id}/history`.
    *   `UsersController.cs`: Manages profile retrieval and updates.
    *   `NotificationsController.cs`: Handles `GET /Notifications/unread`.

### Backend/Logic Gaps
*   **Lack of Pagination**: Endpoints like `/Appointments/student/{id}/history` return the entire historical list of appointments in a single JSON array. This is a severe scalability gap.
*   **Direct Entity Exposure**: The API returns full entity models rather than lightweight DTOs (Data Transfer Objects), potentially leaking unnecessary database fields to the mobile client and increasing payload size.
*   **N+1 Query Risks**: If the `AppointmentsController` fetches associated `Doctor` entities without using Entity Framework's `.Include()`, it may trigger N+1 queries under load.

### Database Dependencies
*   **Tables Used**: `Users` (Role = Student), `Appointments` (Foreign Key: `PatientId`), `Notifications` (Foreign Key: `UserId`).
*   **Relationships**: 1:N between `Users` and `Appointments`.

---

## 2. Faculty Architecture, Gaps & Crash Risks

### Frontend (Flutter) Architecture
*   **Dashboard Module (`lib/app/modules/faculty/dashboard/`)**:
    *   **Controller**: `FacultyDashboardController` handles state. It mirrors the Student controller heavily, utilizing `Future.wait()` for data fetching and a reactive `isLoading` boolean. Listens to `AppointmentEventService` for global refresh triggers.
    *   **Screen**: `FacultyDashboardScreen` uses a `RefreshIndicator` wrapping a `SingleChildScrollView`. Features welcome cards and dynamic statistic calculations.
*   **Key Distinctions**: Faculty profiles display specific fields (e.g., Department) and route to faculty-specific endpoints.

### Frontend Stability & Crash Risks
*   **Global Refresh Overhead**: In `FacultyDashboardController.onInit()`, the `eventService.stream.listen` triggers a full `refresh()` (which re-fetches all dashboard data) whenever *any* appointment event occurs, rather than selectively updating the cached lists. This causes unnecessary network load and UI flickering.
*   **Silent Failures**: The `loadAppointments` block catches errors (`catch (e)`) and simply prints them, clearing the `upcomingAppointments` list. There is no user-facing error snackbar or retry mechanism if the server is unreachable.
*   **Missing State Management Disposal**: If the `AppointmentEventService` subscription is not explicitly cancelled in `onClose()`, navigating away from and back to the dashboard creates duplicate stream listeners (Memory Leak).

### Backend (ASP.NET Core) Architecture
*   **Controllers**: Similar to Student, primarily relying on `AppointmentsController.cs` (filtering by Faculty ID) and `UsersController.cs` (department data).

### Backend/Logic Gaps
*   **Overlapping Roles Logic**: The backend lacks distinct separation between Faculty and Student business logic regarding appointments; both utilize the same endpoints, making role-specific future customizations (e.g., Faculty priority queues) difficult to implement without breaking changes.
*   **Data Aggregation**: Statistics (Total, Completed, Upcoming) are computed on the client side in `FacultyDashboardController._recomputeStatistics()`. This requires fetching the entire array of appointments to the app, which is highly inefficient. The backend should provide a dedicated `/Appointments/summary` endpoint.

### Database Dependencies
*   **Tables Used**: `Users` (Role = Faculty, populated `Department` column), `Appointments`.

---

## 3. Doctor Architecture, Gaps & Crash Risks

### Frontend (Flutter) Architecture
*   **Dashboard Module (`lib/app/modules/doctor/dashboard/`)**:
    *   **Controller**: `DoctorDashboardController` manages distinct state arrays: `todayAppointments`, `upcomingAppointments`, and counts (`totalPatients`, `completedToday`, `pendingToday`).
    *   **Screen**: `DoctorDashboardScreen` contains complex action logic, including buttons for "Confirm", "Decline", and "Mark as Checked" directly on appointment cards.
*   **Key Modules**: Patients List, Schedule Settings, Leave Management.

### Frontend Stability & Crash Risks
*   **State Mutation Syncing**: When a doctor clicks "Confirm" or "Mark as Checked" on an appointment, the UI relies on an optimistic update or a full dashboard refresh. If the API call fails, the UI might fall out of sync with the database unless carefully rolled back.
*   **UI Thread Blocking**: Sorting or filtering large lists of patients in the GetX controller on the main thread can cause frame drops and UI freezing on lower-end Android devices.
*   **Dialog State Issues**: When declining an appointment, a `Get.defaultDialog` is opened with a `TextEditingController` for the reason. If the user dismisses the dialog via hardware back button, the controller might not be properly disposed, leading to potential memory leaks.

### Backend (ASP.NET Core) Architecture
*   **Controllers**:
    *   `AppointmentsController.cs`: Handles state transitions (Pending -> Confirmed -> Completed) and `GET /Appointments/doctor/{id}`.
    *   `DoctorLeavesController.cs`: Manages doctor unavailability and schedule blocking.

### Backend/Logic Gaps
*   **Concurrency Conflicts**: If a patient cancels an appointment exactly when a doctor clicks "Confirm", the backend might throw an unhandled exception or corrupt the status due to a lack of optimistic concurrency control (e.g., RowVersion) on the `Appointments` table.
*   **Schedule Validation**: When a doctor sets a leave (`DoctorLeavesController`), the backend logic must ensure it safely handles or reassigns existing appointments during that time. If not strictly enforced, patients could be left with "Confirmed" appointments for an absent doctor.

### Database Dependencies
*   **Tables Used**: `Users` (Role = Doctor, populated `Specialization` column), `Appointments` (Foreign Key: `DoctorId`), `DoctorLeaves`.

---

## 4. Admin Architecture, Gaps & Crash Risks

### Frontend (Flutter) Architecture
*   **Dashboard Module (`lib/app/modules/admin/dashboard/`)**:
    *   **Screen**: `AdminDashboardScreen` uses `fl_chart` for complex statistical visualizations and a massive grid of `DashboardStatCard` widgets.
*   **User Management (`lib/app/modules/admin/manage_users/`)**:
    *   **Controller**: `ManageUsersController` fetches and filters the entire user base.
    *   **Screen**: `ManageUsersScreen` renders a searchable, filterable list of users with action toggles for Activate/Deactivate and Delete.

### Frontend Stability & Crash Risks
*   **Severe UI Freezing (List Management)**: In `ManageUsersScreen.dart`, the controller loads all users into `controller.filteredUsers` and renders them via `ListView.builder`. Without API-level pagination, loading hundreds of users will parse massive JSON payloads on the main thread, causing severe UI hangs and Potential Application Not Responding (ANR) crashes.
*   **Search Inefficiency**: The local search implementation (`controller.updateSearch`) filters a potentially massive Dart list on every keystroke without a debounce mechanism, severely degrading typing performance.
*   **Missing Guardrails**: The "Delete User" action opens a dialog, but deleting a user with existing foreign key constraints (e.g., active appointments) might throw an unhandled backend exception, causing the frontend to hang in a loading state if the `catch` block does not reset `isLoading.value`.

### Backend (ASP.NET Core) Architecture
*   **Controllers**:
    *   `AdminController.cs` / `UsersController.cs`: Handles broad data retrieval (System stats, all users, verifications).

### Backend/Logic Gaps
*   **Missing Pagination & Filtering**: The `GET /Users` endpoint returns the entire database table. The backend must implement `?page=1&limit=20&search=xyz` to shift the computational load off the mobile device.
*   **Soft Delete vs Hard Delete**: Admin deletion of users likely triggers a hard DELETE in the database. If cascade deletion is improperly configured, it will orphan records or throw SQL constraint errors. A Soft Delete (e.g., `IsDeleted = true`) mechanism is safer.

### Database Dependencies
*   **Tables Used**: Full schema access (`Users`, `Appointments`, `DoctorLeaves`, `Feedback`).

---

## 5. Global System Gaps & Crash Risks

### Architecture & Security Gaps
1.  **JWT Token Lifecycle**: The system relies on JWTs but lacks a Refresh Token architecture. If a token expires during a critical operation (like booking an appointment), the request will fail (401 Unauthorized), and the user will likely be abruptly logged out and lose their input data.
2.  **No Centralized Error Handling**: Both the Flutter frontend and ASP.NET backend lack robust centralized error interceptors. Frontend API calls repeatedly use local `try/catch` blocks, leading to inconsistent user feedback (some show snackbars, some fail silently).
3.  **Payment/Routing Bypass**: The system successfully bypasses commercial payment gateways in favor of direct database connectivity and internal routing, as requested by the architectural requirements, but this requires robust internal logging to ensure appointment state tracking is foolproof.

### Infrastructure & Database Risks
1.  **Missing Indexes**: Without explicit non-clustered indexes on columns like `Appointments.Status`, `Appointments.PatientId`, and `Users.Role`, database performance will degrade exponentially as the platform scales at BUITEMS.
2.  **Timezone Mishandling**: If the backend does not enforce UTC for all `DateTime` storage, timezone discrepancies between the server and the Flutter client (especially if deployed globally or accessed via VPN) will cause appointments to display at incorrect times.
