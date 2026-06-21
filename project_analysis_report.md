# Medi-AI Healthcare & Appointment System - Project Analysis

This document provides a comprehensive structural and functional analysis of the **Medi-AI** project, detailing the architecture, key components, and file structures for both the Frontend (Flutter) and Backend (.NET 8.0).

> [!NOTE]
> The project follows a modern client-server architecture. The frontend is built using **Flutter** with **GetX** for state management, while the backend is a robust **ASP.NET Core 8.0 Web API** using **MySQL** via Entity Framework Core.

---

## 📱 Frontend Analysis (Flutter App)

The frontend is a cross-platform mobile application utilizing Flutter. It heavily relies on the **GetX** package for state management, dependency injection, and routing.

### 1. Root Configuration Files
- [**`pubspec.yaml`**](file:///c:/D/FYP/Medi-AI_F-B-main/pubspec.yaml): The core configuration file for the Flutter project.
  - **State/Routing**: `get`
  - **Networking**: `dio`
  - **Storage**: `hive`, `flutter_secure_storage`, `shared_preferences`
  - **UI**: `google_fonts`, `lottie`, `shimmer`, `cached_network_image`
- [**`analysis_options.yaml`**](file:///c:/D/FYP/Medi-AI_F-B-main/analysis_options.yaml): Linting rules for Dart code quality.

### 2. `lib/` Directory Structure

#### Core Application Files
- [**`lib/main.dart`**](file:///c:/D/FYP/Medi-AI_F-B-main/lib/main.dart): The entry point of the Flutter app. Initializes Hive, GetX routing, and core services before running the `MyApp` widget.

#### Configuration (`lib/config/`)
- [**`app_theme.dart`**](file:///c:/D/FYP/Medi-AI_F-B-main/lib/config/app_theme.dart): Contains the global theme definitions, colors, typography (Google Fonts), and standardized UI aesthetics.
- [**`app_config.dart`**](file:///c:/D/FYP/Medi-AI_F-B-main/lib/config/app_config.dart): Holds global configuration variables like API base URLs and environment toggles.

#### Application Modules (`lib/app/modules/`)
This is where the feature-based code lives. Each directory likely contains its own View, Controller, and Binding (GetX pattern).
- **`auth/`**: Registration, Login, OTP verification screens.
- **`admin/`**: Dashboard and user management for system administrators.
- **`doctor/`**: Doctor-specific views (dashboard, schedule, appointments).
- **`student/`**: Patient/Student views (booking appointments, medical history, symptom checking).
- **`faculty/`**: Faculty-specific features.
- **`common/`**: Shared or generic screens.

#### Infrastructure & Data (`lib/app/`)
- **`data/`**: Likely contains data models, API providers (Dio instances), and repository classes that communicate with the backend.
- **`routes/`**: Defines the application's page routes using GetX (`GetPage` arrays).
- **`services/`**: Global background services (e.g., Auth service checking login state, Notification services).
- **`widgets/`**: Reusable UI components used across multiple screens (e.g., custom buttons, text fields, cards).

---

## ⚙️ Backend Analysis (.NET 8.0 API)

The backend is an enterprise-grade ASP.NET Core API (`Backend-APIs.csproj`) optimized for deployment (e.g., Railway). 

### 1. Root & Configuration Files
- [**`Program.cs`**](file:///c:/D/FYP/Medi-AI_F-B-main/Medi_AI_Backend_railway/Backend-APIs/Program.cs): The bootstrap file. 
  - Sets up the Kestrel web server.
  - Injects services (Email, Auth, User, Gemini AI).
  - Configures **JWT Authentication**.
  - Configures the **MySQL DbContext** using Pomelo Entity Framework Core.
  - Adds Swagger, CORS, and Global Exception Middleware.
- [**`appsettings.json`**](file:///c:/D/FYP/Medi-AI_F-B-main/Medi_AI_Backend_railway/Backend-APIs/appsettings.json) / `appsettings.Development.json`: Contains sensitive credentials, connection strings, JWT secret keys, Gmail SMTP settings, and the **Gemini API Key**.

### 2. API Controllers (`Controllers/`)
Endpoints that handle HTTP requests from the Flutter app.
- **`AuthController.cs`**: Handles `/register`, `/login`, `/verify-otp`.
- **`AppointmentsController.cs`**: Manages appointment booking, status updates, and prescriptions.
- **`DoctorsController.cs`**: Doctor search, listings, and dashboards.
- **`AiController.cs` & `SymptomCheckerController.cs`**: Interfaces with the Gemini AI service for symptom analysis.
- **`UsersController.cs`**: User profile management and photo uploads.
- **`AdminController.cs`**: Admin dashboard stats and user moderation.
- Other controllers include: `FeedbackController`, `MedicalHistoryController`, `MedicineRemindersController`.

### 3. Database Models (`Models/`)
Entity Framework classes mapped to MySQL database tables.
- **`MediaidbContext.cs`**: The core Entity Framework context file defining `DbSet` relationships.
- **Key Entities**: 
  - `User.cs` (Base user schema)
  - `Doctor.cs`, `Doctorreview.cs`, `Doctorschedule.cs`
  - `Appointment.cs`, `Todaysappointment.cs`
  - `Prescription.cs`, `Prescriptionmedicine.cs`
  - `Medicinereminder.cs`, `Medicalhistory.cs`
  - `Symptomcheck.cs`

### 4. Business Logic Services (`Services/`)
Interfaces (`I...Service.cs`) and concrete implementations containing the core logic, keeping controllers clean.
- **`AuthService.cs`**: JWT token generation, password hashing, and user authentication logic.
- **`EmailService.cs`**: Sends OTPs and notifications using MailKit (Gmail SMTP).
- **`GeminiAiService.cs`**: Communicates with the Google Gemini (`gemini-1.5-flash`) API for smart healthcare features.
- **`UserService.cs`**: User-specific CRUD operations.

### 5. Data Transfer Objects (`DTOs/`)
Objects used to strictly define the shape of JSON data sent to and from the API, preventing over-posting and hiding internal database schemas.

---

## 🔑 Key Architectural Highlights

1. **AI Integration**: The platform uses **Google Gemini** (`gemini-1.5-flash`) integrated via the backend (`GeminiAiService.cs`) to provide intelligent symptom checking and AI-driven features.
2. **Security**: 
   - Uses JWT (JSON Web Tokens) with 24-hour expiry and refresh token capabilities.
   - Global Exception Middleware ensures the Flutter app always receives a predictable JSON error format rather than raw stack traces.
3. **Database**: Relational MySQL database managed via Entity Framework Migrations (`Migrations/` folder).
4. **State Management**: The frontend strictly adheres to the GetX pattern, separating UI (Views) from logic (Controllers) and external data.

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
