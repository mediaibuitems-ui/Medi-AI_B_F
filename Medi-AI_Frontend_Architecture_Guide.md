# Medi-AI Architecture & Current State Guide

## 0. Executive Summary
Medi-AI is a full-stack medical application comprising a Flutter mobile frontend and a .NET 8 (ASP.NET Core) backend powered by a MySQL database. It facilitates interactions between Students, Faculty, Doctors, and Administrators. This document outlines the architecture, security mechanisms, current state, and known gaps across the stack.

## 1. System Architecture

### 1.1 Frontend (Flutter / GetX)
- **State Management:** GetX (`get: ^4.6.6`) is used for routing, dependency injection, and reactive state management (`.obs`).
- **API Client:** Dio with a custom `AuthInterceptor`. Base URL points to the Railway server.
- **Local Storage:** `shared_preferences` for secure, persistent storage of JWT tokens.
- **Modules:** The `lib/app/modules/` directory strictly isolates features. Each module typically contains a `Screen`, a `Controller`, and a `Binding`.

### 1.2 Backend (.NET 8 ASP.NET Core Web API)
- **Framework:** ASP.NET Core Web API.
- **ORM:** Entity Framework (EF) Core with the Pomelo MySQL provider.
- **Caching:** `IMemoryCache` utilized for heavy computations like `AdminController.GetDashboardStats()` (1-minute TTL).
- **Dependency Injection:** Heavily used for decoupled services (`AuthService`, `NotificationService`, etc.).

### 1.3 Database (MySQL)
- **Migrations:** Managed exclusively via EF Core Migrations (Code-First approach).
- **Relational Schema:** Highly normalized tables (Users, Appointments, Auditlogs, RevokedTokens, SystemSettings, etc.).

---

## 2. Security Architecture & Techniques
Medi-AI employs defense-in-depth security techniques across the stack to ensure data integrity and user privacy:

- **JWT Authentication & Refresh Flow:** The backend issues cryptographically signed JSON Web Tokens. The frontend's `_AuthInterceptor` securely stores these in `SharedPreferences` and transparently handles 401 Unauthorized retries using a `/refresh-token` endpoint before forcing a logout.
- **Token Blacklisting (Logout Revocation):** Upon logout, the JWT signature is hashed (SHA-256) and stored persistently in a `RevokedTokens` database table. A custom ASP.NET Core Middleware (`JwtRevocationMiddleware`) intercepts every request, checks an `IMemoryCache` (pre-loaded from the DB at startup for performance), and rejects blacklisted tokens to prevent replay attacks.
- **Strict Role Normalization:** Roles are strongly typed via C# Constants (`UserRoles.cs`) and Dart Constants (`AppRoles.dart`), eliminating security holes caused by magic strings, casing errors, or typos.
- **IDOR Protection:** Endpoints like appointment cancellation (`DELETE /api/appointments/{id}`) or profile updates strictly verify that `ClaimTypes.NameIdentifier` matches the requested resource's owner or an Admin override.
- **Password Hashing:** Passwords are never stored in plaintext. They are salted and hashed utilizing modern cryptographic standards in the ASP.NET Identity pipeline.

---

## 3. Current State of the Application
The application has recently undergone a massive hardening and backlog completion pass, reaching a highly stable state:

- **Admin Dashboard:** Fully functional with performant stats caching (via `IMemoryCache`), paginated verification lists to prevent memory bloat, truth-in-UI toggles for decorative features (e.g., 2FA/SMS disabled), and schema-backed Audit Logs utilizing the `IconKey` column.
- **Doctor Dashboard:** Secured against unauthorized auto-creation. Features strict settings validation, IDOR-protected schedule management, and state-protected prescription writing workflows that prevent data loss on back-navigation.
- **Faculty Dashboard:** Completely decoupled from Student endpoints, resolving severe data-leakage and IDOR vulnerabilities.
- **Student Dashboard:** End-to-end appointment booking, medical history tracking, and symptom analyzing workflows are active.
- **Performance:** Replaced standalone `Timer.periodic` background polling with centralized `NotificationService` handling, drastically reducing unnecessary server load.

---

## 4. Complete Project Gaps (Frontend, Backend, Database)
While the core architecture is stable, the following technical debts and functional gaps remain:

### 4.1 Frontend Gaps
- **Pagination Missing on Core Lists:** While Verification Requests are paginated, screens like `ManageUsersScreen` and `AdminAppointmentsScreen` currently load all records into memory at once, risking UI freezing and high memory usage at scale.
- **Button Debouncing:** Several primary action buttons (e.g., "Submit" on forms) lack strict debouncing `.obs` flags, risking duplicate API calls if the user rapidly double-taps.
- **Responsive Overflow:** The AI Symptom analyzer dynamic text rows are at risk of pixel `RenderFlex` overflow on smaller devices because they occasionally lack `Expanded` wrappers.
- **Silent Failures on Schema Changes:** Missing rigorous null-checks in Dart model parsing (`.fromJson`). If the backend unexpectedly returns null for a previously non-null field, the app will throw a red screen runtime exception.

### 4.2 Backend Gaps
- **Decorative Communication:** The system contains placeholders for 2FA and SMS/Email OTP notifications. Currently, OTPs are either decorative or only printed to the server console. Integration with a real communications provider (e.g., SendGrid, Twilio) is required for production.
- **Stubbed AI Logic / Fake Reports:** The `SymptomAnalyzerController` relies on hardcoded logic rather than an actual integrated LLM. Similarly, the Admin database backup endpoint currently returns `501 Not Implemented` because no actual MySQL dump logic exists.
- **File Storage Scalability:** Any future features requiring image/document uploads (like Doctor Licenses or Profile Pictures) will fail on ephemeral container hosts (like Railway) unless integrated with an external blob storage provider (e.g., AWS S3 or Azure Blob Storage).
- **Rate Limiting:** There is no global rate limiting applied to the API, making it vulnerable to brute-force attacks on the `/login` and `/register` endpoints.

### 4.3 Database Gaps
- **Data Retention & Archival:** The `Auditlogs` and `RevokedTokens` tables will grow indefinitely. A cron job or background hosted service is needed to automatically purge expired tokens and archive audit logs older than 90 days.
- **Soft Delete Integrity:** Deleting users utilizes a soft-delete mechanism (`IsActive = false`), but no EF Core "Global Query Filters" exist to automatically hide inactive users from standard queries, relying on developers to manually append `.Where(u => u.IsActive == true)`.
- **Missing Composite Indices:** While EF Core automatically creates basic indices on Foreign Keys, heavy queries (like `GetDashboardStats` date filtering) lack specific composite indices. This will degrade database performance as the tables scale beyond thousands of rows.
