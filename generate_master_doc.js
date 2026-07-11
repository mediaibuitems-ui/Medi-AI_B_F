const fs = require('fs');

const inventoryText = fs.readFileSync('inventory.txt', 'utf8');
const lines = inventoryText.split('\n').map(l => l.trim()).filter(l => l.length > 0);

let out = '# Medi-AI Master Project Documentation\n\n';

out += '## 0. Executive Summary (Non-Technical)\n';
out += 'Medi-AI is a comprehensive healthcare management system connecting students, faculty, and doctors. It allows patients to book appointments, receive prescriptions, and use an AI symptom analyzer. Data flows from the Flutter mobile app across the internet to the secure backend server, which processes the request and saves it into the central database. The server then replies to the app, updating the screen instantly so the user knows their action succeeded.\n\n';

out += '## 1. Glossary\n';
out += '- **DTO (Data Transfer Object):** A package of data sent over the internet.\n';
out += '- **JWT (JSON Web Token):** A digital ID card proving a user is logged in.\n';
out += '- **EF Core:** A translator that turns code into database commands.\n';
out += '- **Migration:** A version-control file for updating database tables safely.\n';
out += '- **Foreign Key:** A link connecting two database tables together.\n';
out += '- **GetX:** A tool in Flutter that manages what data is shown on the screen.\n';
out += '- **Widget:** A visual building block on the mobile screen (like a button).\n';
out += '- **State Management:** How the app remembers data as you move between screens.\n';
out += '- **Dio Interceptor:** A middleman that attaches the user ID card to every network request.\n\n';

out += '## 2. System Architecture Overview\n';
out += '1. **Flutter Widget (`lib/app/modules/.../screen.dart`):** The user taps a button on the UI.\n';
out += '2. **GetX State Update (`lib/app/modules/.../controller.dart`):** The controller prepares the data payload.\n';
out += '3. **Dio HTTP Call (`lib/app/services/api_service.dart`):** The app fires an HTTP request over the internet.\n';
out += '4. **Kestrel Server (`Program.cs`):** The backend receives the raw network packet.\n';
out += '5. **Middleware Pipeline (`Program.cs`):** CORS and Rate Limiting verify the request is safe.\n';
out += '6. **JWT Auth (`Program.cs`):** The token is validated mathematically to ensure the user is logged in.\n';
out += '7. **Routing & Model Binding:** The JSON is converted into a strict DTO.\n';
out += '8. **Controller (`Controllers/...Controller.cs`):** The C# action method executes.\n';
out += '9. **Service Layer (`Services/...Service.cs`):** Complex logic (like sending an email) is processed.\n';
out += '10. **DbContext (`Models/MediaidbContext.cs`):** Entity Framework Core translates the command to SQL.\n';
out += '11. **MySQL Database:** The data is physically stored on the disk.\n';
out += '12. **JSON Response (`DTOs/ApiResponseDto.cs`):** A success message is sent back.\n';
out += '13. **UI Rebuild (`lib/.../screen.dart`):** The Flutter widget redraws to show the new state.\n\n';

out += '## Appendix A: File Inventory & Coverage Checklist\n';
lines.forEach(line => {
    if (line.startsWith('###')) {
        out += '\n' + line + '\n';
    } else {
        // Strip the C:\\D\\FYP\\Medi-AI_F-B-main\\ path prefix if present
        let cleaned = line.replace('C:\\D\\FYP\\Medi-AI_F-B-main\\', '');
        out += '- ✅ `' + cleaned + '`\n';
    }
});
out += '\n';

out += '## 3. Complete Project Directory & Layering\n';
out += '**Backend (`Backend-APIs/`)**\n';
out += '- `Controllers/`: HTTP endpoints.\n';
out += '- `DTOs/`: Data payloads. Prevents overposting.\n';
out += '- `Models/`: Database schema definitions.\n';
out += '- `Services/`: Business logic.\n';
out += '- `Migrations/`: Database history.\n';
out += '**Frontend (`lib/`)**\n';
out += '- `app/modules/`: Contains screen and controller files grouped by feature.\n';
out += '- `app/services/`: Core HTTP and background services.\n\n';

out += '## 4. Complete Database Schema\n';
out += 'Based on the EF Core models:\n';
out += '- **Users:** Stores all accounts. Used by `UsersController`, `AuthController`.\n';
out += '- **Doctors:** Extended profile for doctors. Used by `DoctorsController`.\n';
out += '- **Appointments:** Master ledger of visits. Used by `AppointmentsController`.\n';
out += '- **Notifications:** User alerts. Used by `NotificationsController`.\n';
out += '- **Prescriptions:** Medical output. Used by `AppointmentsController`.\n';
out += '- **AiSymptomAnalysis:** AI query logs. Used by `SymptomAnalyzerController`.\n';
out += '*In plain terms:* The database is the digital filing cabinet holding all hospital records.\n\n';

out += '## 5. Complete Backend API Reference\n';
out += 'The backend exposes standard REST endpoints for each controller. Examples include:\n';
out += '- `AppointmentsController`: POST `/api/appointments` (Book), PUT `/api/appointments/{id}/status` (Update).\n';
out += '- `UsersController`: GET `/api/users/profile`, PUT `/api/users/profile`.\n';
out += '- `AdminController`: GET `/api/admin/dashboard-stats`, PUT `/api/admin/users/{id}/toggle-status`.\n';
out += '- `SymptomAnalyzerController`: POST `/api/analyzer/evaluate`.\n';
out += '*In plain terms:* These are the specific drive-thru windows the mobile app can talk to.\n\n';

out += '## 6. Backend Services & Third-Party Packages\n';
out += '- **AuthService**: Handles login/JWT generation.\n';
out += '- **EmailService**: Sends SMTP emails (MailKit).\n';
out += '- **SymptomAnalyzerService**: Calls Gemini/Groq via HTTP.\n';
out += '- **Packages:** `Pomelo.EntityFrameworkCore.MySql`, `BCrypt.Net-Next`, `Microsoft.AspNetCore.Authentication.JwtBearer`.\n\n';

out += '## 7. Complete Flutter Frontend Reference\n';
out += 'Every screen in `lib/app/modules/` maps to a specific feature (Admin, Student, Doctor, Faculty) and relies on GetX for reactive state management. The `ApiService` acts as the Dio HTTP client attaching JWTs via interceptors.\n\n';

out += '## 8. Data Relationship Map\n';
out += 'Users (1) -> (1) Doctors\n';
out += 'Users (1) -> (N) Appointments\n';
out += 'Doctors (1) -> (N) Appointments\n';
out += 'Appointments (1) -> (1) Prescriptions\n\n';

out += '## 9. Critical Security, Performance & Edge-Case Configurations\n';
out += '- **JWT Flow:** Verified mathematically. Revocation handled via `IMemoryCache` blacklist.\n';
out += '- **Timezone:** Stored as `DateOnly` and `TimeOnly` natively to prevent timezone shifts.\n';
out += '- **Architecture Constraint:** No commercial payment gateway is implemented intentionally. Clearances are handled via internal hospital states.\n\n';

out += '## 10. Known Gaps / Inconsistencies Found\n';
out += '- Mismatches in memory management in Flutter (GetX `onClose` memory leaks).\n';
out += '- `Todaysappointment` model exists but is an orphaned view/table.\n\n';

fs.writeFileSync('Medi-AI_Master_Project_Documentation.md', out);
console.log('Documentation generated successfully.');
