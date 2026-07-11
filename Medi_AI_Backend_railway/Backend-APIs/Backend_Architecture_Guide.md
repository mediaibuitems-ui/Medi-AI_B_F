# Medi-AI Backend Architecture Guide

**Author:** Principal Software Architect
**Scope:** ASP.NET Core API Backend, Entity Framework Core Database Layer
**Version:** 1.0

This exhaustive guide serves as the ultimate source of truth for the Medi-AI backend system architecture, documenting every layer, service, routing mechanism, and database structure. 

---

## 1. Global Request-Response Lifecycle Flow

The backend employs a strictly typed, fully decoupled layered architecture. When the Flutter client fires a request (via `Dio`), the exact lifecycle is as follows:

### 1. Kestrel Web Server & Initial Middleware Pipeline
- The request hits **Kestrel** (the internal web server hosting ASP.NET Core) on port `8080` (or Railway's environment port).
- It first encounters the **Rate Limiter** middleware (`app.UseRateLimiter()`), which protects the `/api/Auth` endpoints (max 5 requests per minute per IP to prevent brute force attacks).
- It then passes through **CORS** (`app.UseCors("DefaultCors")`), which verifies the client's origin (specifically tuned for production vs. localhost).

### 2. Custom Authentication & Blacklist Filter
- The request passes into `app.UseAuthentication()`. The **JwtBearer middleware** checks the `Authorization: Bearer <token>` header.
- The JWT is parsed, and the Signature, Audience, and Expiry are validated mathematically using the secret `Jwt:Key`.
- Next, a **Custom JWT Revocation Middleware** executes. It extracts the raw token and checks the injected `IMemoryCache` for `"Blacklist_{token}"`. If found, it instantly short-circuits the pipeline with a `401 Unauthorized` without touching the database.

### 3. API Routing and Model Binding
- `app.UseAuthorization()` executes role-based checks (`[Authorize(Roles = "Admin")]`).
- The framework uses reflection (`app.MapControllers()`) to route the URI path (e.g., `POST /api/appointments`) to the correct Controller class.
- The JSON payload is automatically deserialized into a strict **Data Transfer Object (DTO)** (e.g., `CreateAppointmentDto`). Model validation ensures all `[Required]` fields are populated. If invalid, the `ApiBehaviorOptions` intercepts and formats a standardized HTTP 400 `ApiResponse<T>`.

### 4. Controller Layer & Action Methods
- The request enters the action method. The controller's *only* job is routing and HTTP response formulation. 
- Claims are extracted. The `userId` is pulled securely from `User.FindFirst(ClaimTypes.NameIdentifier)` to prevent ID spoofing.

### 5. Application Services / Business Logic Layer
- Complex logic (like sending emails or pushing real-time notifications) is abstracted out into injected scoped services (e.g., `IAuthService`, `IEmailService`, `INotificationPushService`). 
- This guarantees that business rules exist independently of HTTP context.

### 6. Data Access Layer (EF Core)
- The Controller uses injected `MediaidbContext` to query or modify data.
- LINQ queries are converted into strictly parameterized MySQL queries to prevent SQL Injection.
- Calls like `await _context.SaveChangesAsync()` commit changes inside atomic transactions.

### 7. Response Transformation
- The result is wrapped into a standardized envelope:
```json
{
  "success": true,
  "message": "Action completed",
  "data": { ... }
}
```
- The JSON is serialized and streamed back to the Flutter client.

---

## 2. Complete Project File Directory & Layering

The architecture heavily decouples the Database schema from the API contract to prevent over-posting vulnerabilities.

```text
Backend-APIs/
├── Controllers/         # The entry points. Defines HTTP routes and binds DTOs.
├── DTOs/                # Data Transfer Objects. Flat, stateless classes mapping JSON bodies.
├── Models/              # Entity Framework Models. Maps 1:1 with actual MySQL database tables.
├── Services/            # Abstractions for third-party operations (Email, Auth, Notifications).
├── Middleware/          # Global Pipeline Filters (GlobalExceptionMiddleware.cs).
├── Migrations/          # EF Core version history tracking structural database changes.
├── Program.cs           # The dependency injection (DI) container and pipeline bootstrapper.
├── appsettings.json     # Configuration variables (DB connections, secrets).
└── Dockerfile           # OCI image build instructions for Railway production deployment.
```

**Why this structure?**
By separating `Models` (Entities) from `DTOs` (Payloads), we guarantee that a malicious user cannot pass a JSON payload containing `{"IsAdmin": true}` to elevate their privileges, because the `DTO` explicitly ignores fields that the client is not permitted to mutate.

---

## 3. Controller & Action Method Deep-Dive

### A. AppointmentsController
Handles routing, booking, and complex state machine transitions for medical appointments.
*   **`POST /api/appointments` (Book Appointment)**
    *   **Purpose:** Allows students/faculty to book an appointment. Validates doctor availability, checks for schedule overlaps, and prevents booking in the past.
    *   **Payload:** `CreateAppointmentDto` (DoctorId, AppointmentDate, AppointmentTime, Symptoms).
    *   **Tables Triggered:** Queries `Doctors`, `DoctorLeaves`, `Appointments`. Inserts into `Appointments`, `Notifications`.
    *   **Response:** The newly created `AppointmentDto`.
*   **`GET /api/appointments/my` (List User Appointments)**
    *   **Purpose:** Fetches history and upcoming bookings for the logged-in user.
    *   **Tables Triggered:** Joins `Appointments`, `Users`, `Doctors`.
*   **`PUT /api/appointments/{id}/status` (Update Status)**
    *   **Purpose:** Modifies appointment state (e.g., Pending -> Confirmed -> Completed -> Cancelled). Strictly enforces role access (only Admins or the assigned Doctor can confirm).
    *   **Payload:** `{ "status": "Confirmed" }`
    *   **Tables Triggered:** Updates `Appointments.Status`, triggers `Notifications`.

### B. UsersController
Handles profile configurations and batch queries.
*   **`GET /api/users/profile`**
    *   **Purpose:** Retrieves the authenticated user's profile based strictly on their JWT `NameIdentifier` claim.
    *   **Tables Triggered:** `Users`.
*   **`PUT /api/users/profile`**
    *   **Purpose:** Updates bio-data (Address, Phone Number). Prevent modification of Role/RegistrationNumber.
    *   **Payload:** `UpdateProfileDto`.
*   **`GET /api/users/department/{dept}`**
    *   **Purpose:** Fetches all users within a specific academic department.

### C. NotificationsController
Manages dispatch and retrieval of contextual updates.
*   **`GET /api/notifications`**
    *   **Purpose:** Retrieves all unread alerts (appointment confirmations, prescription updates) for the logged-in user.
    *   **Tables Triggered:** `Notifications`.
*   **`PUT /api/notifications/{id}/read`**
    *   **Purpose:** Flips the `IsRead` boolean to true.
    *   **Tables Triggered:** `Notifications`.

### D. DoctorsController (Including DoctorLeaves)
*   **`GET /api/doctors` & `GET /api/doctors/{id}`**
    *   **Purpose:** Lists available doctors and their specializations for the booking screen.
*   **`POST /api/doctors/leaves`**
    *   **Purpose:** Allows a doctor to register a blackout window where they are unavailable. Checks for existing overlapping appointments and blocks the leave if appointments exist (or requires admin override).
    *   **Payload:** `AddLeaveDto` (StartDate, EndDate, Reason).
    *   **Tables Triggered:** Inserts into `DoctorLeaves`.
*   **`GET /api/doctors/leaves`**
    *   **Purpose:** Fetches the logged-in doctor's leave history.

### E. AdminController
*   **`GET /api/admin/dashboard-stats`**
    *   **Purpose:** Computes heavy aggregations for the admin UI.
    *   **Tables Triggered:** Counts rows across `Users`, `Doctors`, `Appointments`, `Prescriptions`.
*   **`PUT /api/admin/users/{id}/toggle-status`**
    *   **Purpose:** Activates or Deactivates a user's account. Deactivated users cannot authenticate.
    *   **Tables Triggered:** Updates `Users.IsActive`.

---

## 4. Specialized Core Services & Third-Party Packages

### Large Language Model Service (Gemini/Groq Integration)
The system integrates an AI Symptom Analyzer (`SymptomAnalyzerController`). 
- **Data Flow:** The Flutter client sends a list of symptoms (e.g., "headache, fever"). The backend extracts this payload, applies internal hospital constraints, and securely wraps it into a strict system prompt.
- **Execution:** It makes a server-to-server outbound HTTP request to the LLM API using the `ApiKey` stored in environment variables. 
- **Security:** The API key *never* reaches the Flutter frontend. The response from the LLM is parsed, deserialized into a `SymptomAnalyzerResponseDto` (Condition, Confidence), logged into the `AiSymptomAnalysis` database table for historical auditing, and sent back to the client.

### Core NuGet Packages
- **`Microsoft.EntityFrameworkCore.Design` & `Pomelo.EntityFrameworkCore.MySql`**
  - **Purpose:** Acts as the ORM (Object Relational Mapper). `Pomelo` translates LINQ C# queries into optimized MySQL dialects. The connection strings are dynamically generated via `Program.cs` environment variable parsing (allowing seamless Railway database injection).
- **`Microsoft.AspNetCore.Authentication.JwtBearer`**
  - **Purpose:** Handles the cryptographic verification of the JSON Web Token signature without requiring manual byte-array inspection.

---

## 5. Database Schema & Relational Dependencies

The schema is heavily relational. Key constraints include:

- **Users (1) -> (N) Appointments:** A `Patient` (User) has multiple appointments. Foreign Key: `PatientId`.
- **Users (1) -> (1) Doctors:** A `Doctor` is an extension of a `User`. They share the same authentication logic, but `Doctors` possess specific fields (Specialization, LicenseNumber). Foreign Key: `UserId` on the `Doctors` table.
- **Doctors (1) -> (N) DoctorLeaves:** Tracks availability.
- **Appointments (1) -> (1) Prescriptions:** A completed appointment optionally generates exactly one medical prescription record.

> [!IMPORTANT]
> **Architectural Constraint:** 
> The architecture relies strictly on a localized internal routing system. No external payment gateways (like Stripe) are integrated. State transitions (e.g., Pending to Completed) are handled via internal Role-Based Access Control logic without reliance on financial clearance status.

---

## 6. Critical Security, Performance & Edge-Case Configurations

### JWT Mechanics & Validation
1. **Extraction:** The token is read from the HTTP Header.
2. **Context Parsing:** The `userId` is parsed natively by the `[Authorize]` filter pipeline. The backend **never** trusts a `userId` passed inside a JSON body for mutating user-specific data; it strictly relies on `User.FindFirstValue(ClaimTypes.NameIdentifier)`.
3. **Revocation:** Tokens are stateless. To enable instantaneous logouts or forced bans, the backend caches the specific token string in memory for the duration of its expiry.

### Timezone & Date Standards
- All incoming Dates (`AppointmentDate`, `CreatedAt`) are parsed securely.
- To prevent cross-timezone booking collisions (e.g., a student booking from a different timezone than the server), all database timestamp comparisons rely on standardized backend comparisons (`DateOnly` for appointment dates, `TimeSpan` for slots). Timezone coercion is handled gracefully by EF Core prior to insertion.
