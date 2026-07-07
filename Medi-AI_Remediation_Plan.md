# Medi-AI Remediation Plan: Architectural Fixes & Optimization

This document outlines a strict, phased execution plan to resolve the architectural flaws, stability gaps, and crash risks identified in the Medi-AI audit. Tasks are categorized by their target domain (Database, Backend, Frontend) and prioritized by criticality.

---

## Phase 1: Critical Data Integrity & Security (Immediate Action)

### 1.1 Address JWT Claim Mismatch in AI Analyzer
* **Domain**: Backend (C#)
* **Target File**: `Medi_AI_Backend_railway/Backend-APIs/Controllers/SymptomAnalyzerController.cs`
* **Issue**: The symptom analyzer controller attempts to parse the user ID from the `"id"` claim: `User.Claims.FirstOrDefault(c => c.Type == "id")?.Value`. If the JWT token was issued with `ClaimTypes.NameIdentifier` (or `"nameid"`) instead of exactly `"id"`, `int.TryParse` will fail or return 0, leading to unauthorized errors or corrupted foreign keys.
* **Fix**: Update the user ID extraction logic to check both standard XML schema claims and raw JWT claims.
  ```csharp
  var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value 
                    ?? User.Claims.FirstOrDefault(c => c.Type == "id")?.Value;
  ```

### 1.2 Address Orphaned Database Tables
* **Domain**: Database & Backend (Entity Framework)
* **Issue**: Development iterations often leave orphaned tables (e.g., `SymptomChecks`) in the database that don't match the active EF Core models (`AiSymptomAnalyses`).
* **Fix**: 
  1. Generate a new EF Core migration (`dotnet ef migrations add CleanupOrphanedTables`).
  2. Inside the generated migration `.cs` file, explicitly add `migrationBuilder.DropTable(name: "SymptomChecks");` in the `Up` method.
  3. Run `dotnet ef database update` to align the production schema.

### 1.3 Fix N+1 Query Risks in Appointments Controller
* **Domain**: Backend (C#)
* **Target File**: `Medi_AI_Backend_railway/Backend-APIs/Controllers/AppointmentsController.cs`
* **Issue**: While the `GetAllAppointments` method correctly uses `.Include()`, other potential endpoints or internal service calls might fetch child entities (like `User` details inside a `Doctor` entity) lazily inside loops, causing severe N+1 database queries.
* **Fix**: Ensure *every* query that maps `AppointmentResponseDto` explicitly chains the `.Include()` statements for navigation properties.
  ```csharp
  // Example enforcement in the query chain:
  var appointments = await _context.Appointments
      .Include(a => a.Patient)
      .Include(a => a.Doctor)
          .ThenInclude(d => d.User) // CRITICAL: Prevent N+1 on Doctor's User details
      .Include(a => a.Prescriptions)
      .AsNoTracking() // Ensure read-only performance
      .ToListAsync();
  ```

---

## Phase 2: Backend API Scalability & Optimization

### 2.1 Implement API Pagination
* **Domain**: Backend (C#)
* **Target Files**: `UsersController.cs`, `AppointmentsController.cs`
* **Issue**: `/Appointments/student/{id}/history` and `/Users` endpoints return massive unbounded JSON arrays.
* **Fix**: Introduce pagination query parameters (`[FromQuery] int page = 1, [FromQuery] int limit = 20`). 
  ```csharp
  var query = _context.Appointments.Where(a => a.PatientId == patientId);
  var totalCount = await query.CountAsync();
  var pagedData = await query
      .Skip((page - 1) * limit)
      .Take(limit)
      .ToListAsync();
  // Return alongside totalCount for frontend tracking
  ```

### 2.2 Transition to Lightweight DTOs
* **Domain**: Backend (C#)
* **Issue**: Returning raw Entity objects exposes database architecture and bloats payloads.
* **Fix**: Define dedicated Response DTOs for heavy objects like `User`. Instead of returning the raw `User` entity in `UsersController`, map it to a `UserSummaryDto` containing only `Id`, `FullName`, `Role`, and `ProfileImage`. 

### 2.3 Optimize Direct Contact System (Constraint Checked)
* **Domain**: Backend (C#) & Frontend (Flutter)
* **Constraint Compliance**: No commercial payment gateway (Stripe/PayPal) will be introduced. 
* **Fix**: To ensure the direct-contact hospital system functions seamlessly, the backend must implement strict state locking on the `Appointments` table using optimistic concurrency (e.g., adding a `RowVersion` column) to prevent double-booking of doctors, completely eliminating the need for transactional payment locks.

---

## Phase 3: Frontend Stability & Crash Prevention (Flutter)

### 3.1 Resolve GetX Memory Leaks
* **Domain**: Frontend (Flutter)
* **Target Files**: `FacultyDashboardController.dart`, `DoctorDashboardController.dart`
* **Issue**: Stream listeners (like `AppointmentEventService.stream.listen`) and `TextEditingController`s inside dialogs are not explicitly disposed of when controllers are destroyed.
* **Fix**: Override the `onClose()` method in GetX controllers.
  ```dart
  late StreamSubscription _eventSubscription;
  
  @override
  void onInit() {
    _eventSubscription = eventService.stream.listen(...);
  }
  
  @override
  void onClose() {
    _eventSubscription.cancel(); // Prevent memory leak
    super.onClose();
  }
  ```

### 3.2 Fix RenderFlex Overflows in AI Analyzer
* **Domain**: Frontend (Flutter)
* **Target File**: `lib/app/modules/student/symptom_analyzer/ai_symptom_result_screen.dart`
* **Issue**: The dynamically generated lists (Recommendations, Home Care) can overflow on small screens if nested rows lack flex constraints.
* **Fix**: Ensure that any text displaying dynamic AI output inside a `Row` is wrapped in an `Expanded` widget. The current implementation uses `Expanded` around the text, but the parent `SingleChildScrollView` must be tested to ensure the `ListView.builder(shrinkWrap: true)` does not cause layout pipeline failures on deeply nested components. Replace `shrinkWrap: true` lists with a unified `SliverList` within a `CustomScrollView` for peak rendering performance.

### 3.3 Implement UI Pagination / Infinite Scrolling
* **Domain**: Frontend (Flutter)
* **Target Files**: `ManageUsersScreen.dart`, `my_appointments_screen.dart`
* **Fix**: Attach a `ScrollController` to the `ListView`. Add a listener to detect when the user scrolls near the bottom (`scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200`). When triggered, increment the `page` variable in the GetX controller and fetch the next chunk of data from the newly paginated backend endpoints, appending it to the observable list.

### 3.4 Strict Loading States on Action Buttons
* **Domain**: Frontend (Flutter)
* **Target File**: `StudentDashboardScreen.dart`, `DoctorDashboardScreen.dart`
* **Issue**: Users can double-tap "Book Appointment" or "Confirm" before the API responds.
* **Fix**: Wrap button `onPressed` handlers in an `Obx` boolean check (`isSubmitting.value`). If true, return `null` (disabling the button) and display a `SizedBox(height: 16, width: 16, child: CircularProgressIndicator())` instead of the button text.

---

## Phase 4: Global Error Handling & Edge Cases

### 4.1 Centralized Interceptors (Flutter & C#)
* **Backend (C#)**: Implement a global `ExceptionMiddleware` that catches all unhandled exceptions, formats them into a standard `ApiResponse { Success = false, Message = "Internal Server Error" }`, and logs the actual stack trace to the console or Application Insights. This prevents raw HTML error pages from crashing the Flutter JSON parser.
* **Frontend (Flutter)**: In `api_service.dart`, enhance the `_LoggingInterceptor` or `_handleError` method to globally catch 500 status codes and trigger a unified `Get.snackbar('System Error', 'Please try again later')`, removing the need for repetitive try/catch blocks in every GetX controller.

### 4.2 Graceful JWT Expiration Handling
* **Domain**: Frontend (Flutter)
* **Target File**: `lib/app/services/api_service.dart` (Inside `_AuthInterceptor`)
* **Issue**: If the token expires and the silent refresh fails (or no refresh token exists), the user is abruptly kicked to the login screen, losing state.
* **Fix**: Before calling `Get.offAllNamed('/login')`, inject a user-friendly dialog or snackbar indicating the session has expired. Furthermore, explicitly save the user's last intended route in the `StorageService` so that post-login, the app can redirect them back to where they were, preserving the UX flow.
