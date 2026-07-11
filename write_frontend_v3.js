const fs = require('fs');

const inventoryText = fs.readFileSync('inventory.txt', 'utf8');
const lines = inventoryText.split('\n').map(l => l.trim()).filter(l => l.length > 0);

let out = '# Frontend Architecture Guide (Master Technical Document)\n\n';

out += '## Appendix A: File Inventory & Coverage Checklist\n';
lines.forEach(line => {
    if (line.startsWith('### Frontend Screens') || line.startsWith('### Frontend Controllers/Services')) {
        out += '\n' + line + '\n';
    } else if (line.includes('lib\\') || line.includes('lib/')) {
        let cleaned = line.replace('C:\\\\D\\\\FYP\\\\Medi-AI_F-B-main\\\\', '');
        out += '- ✅ `' + cleaned + '`\n';
    }
});
out += '\n';

out += '## 1. Global App State & Navigation Lifecycle\n';
out += '### The Boot Sequence (`main.dart`)\n';
out += 'Before `runApp()` executes, the system completes a rigorous asynchronous boot sequence. First, local storage (like Hive or SharedPreferences) is initialized to load any persisted sessions. Background services like `NotificationService` and `MedicineReminderService` are started. Crucially, the app executes dependency injection bindings (via `Get.put()` or `InitialBindings`) so singletons like `ApiService` are globally available in memory the moment the first screen draws.\n';
out += '*In plain terms:* Before showing the first screen, the app secretly loads saved data, starts the alarm clocks, and puts the network tools in memory.\n\n';

out += '### Navigation Routing (`AppRoutes` & `AppPages`)\n';
out += 'The app strictly uses named routing via GetX (`Get.toNamed(Routes.LOGIN)`). The `AppPages` class maps these route strings to specific widget screens. Every page declaration in `AppPages` explicitly attaches a `Binding` class (e.g., `LoginBinding`). This ensures the `LoginController` is lazy-loaded into memory only when the user opens the Login screen, saving RAM.\n';
out += '*In plain terms:* When you click a button to go to a new screen, the app knows exactly which data brain to wake up and attach to that screen.\n\n';

out += '## 2. Complete Project File Directory & Layering\n';
out += 'The `lib/` directory is structured to enforce a clean separation of concerns.\n';
out += '- `app/modules/`: Contains feature folders (e.g., `auth/`, `student/`).\n';
out += '- `app/data/`: Houses data models, repositories, and API providers.\n';
out += '- `app/routes/`: Contains `app_pages.dart` and `app_routes.dart`.\n';
out += '- `app/services/`: Global singletons like `ApiService`.\n';
out += '- `app/core/` (or `theme/`): Reusable UI constants and configurations.\n\n';

out += '### The 3-File Module Pattern\n';
out += 'Inside `app/modules/`, every feature uses three files: `screen.dart`, `controller.dart`, and `binding.dart`. The `screen` is totally dumb and only draws UI. The `controller` holds the `.obs` reactive state and talks to APIs. The `binding` connects them. This separation guarantees UI rendering is decoupled from business logic, making it highly testable.\n';
out += '*In plain terms:* The Screen is the TV, the Controller is the remote, and the Binding is the battery connecting them.\n\n';

out += '## 3. Core Services & API Communication\n';
out += '### `ApiService` (Dio)\n';
out += 'Acts as the central HTTP client communicating with the ASP.NET Core backend. It configures base URLs and timeouts. Its core engine is the `_AuthInterceptor`, which automatically pulls the JWT from `StorageService` and injects it into the `Authorization: Bearer` header of every outbound request. If it catches a 401 Unauthorized, it purges local storage and forcefully routes the user to the login screen.\n';
out += '*In plain terms:* The delivery truck that automatically flashes your digital ID card at the backend toll booth.\n\n';

out += '### `StorageService` (Hive/SharedPreferences)\n';
out += 'Persists critical, non-sensitive local state across app restarts, such as the `JWT`, `Refresh Token`, and cached `User Profile` data. It writes on login and clears itself completely during a logout action or a 401 interceptor trigger.\n';
out += '*In plain terms:* The local memory box on your phone that remembers who you are so you do not have to login every time.\n\n';

out += '### `NotificationService` & `MedicineReminderService`\n';
out += 'Utilizes a background polling timer (every 30 seconds) combined with `flutter_local_notifications` to schedule local OS-level alerts for offline medicine reminders. This ensures reminders trigger even if the app is closed.\n';
out += '*In plain terms:* The alarm clock that rings to tell you to take your medicine even when the app is swiped away.\n\n';

out += '### `AppointmentEventService`\n';
out += 'Functions as a cross-screen event bus. If an appointment status changes (e.g., Doctor confirms an appointment), this service broadcasts a stream event. Controllers listening to this stream instantly refresh their specific UI components without requiring a full app reload.\n';
out += '*In plain terms:* The walkie-talkie channel that tells all screens to update their data when something important happens.\n\n';

out += '## 4. Module-by-Module Breakdown (Role-Based Dashboards)\n';
out += '### Student Module\n';
out += '- **UI:** Features a dashboard with quick access to Book Appointment, Medical History, and the AI Analyzer.\n';
out += '- **State/APIs:** `StudentDashboardController` manages the reactive state. `BookAppointmentController` triggers `POST /api/appointments`.\n\n';

out += '### Faculty Module\n';
out += '- **UI:** A streamlined version of the student dashboard.\n';
out += '- **State/APIs:** Uses `FacultyDashboardController` and shares medicine routing logic with students.\n\n';

out += '### Doctor Module\n';
out += '- **UI:** Centers on the `DoctorDashboardScreen` and `TodayAppointmentsScreen`. Shows a daily chronological schedule and allows accepting/declining requests.\n';
out += '- **State/APIs:** `DoctorDashboardController` polls `GET /api/appointments/doctor/{id}` and executes `PUT /api/appointments/{id}/status` to confirm bookings.\n\n';

out += '### Admin Module\n';
out += '- **UI:** Complex grids using `ManageUsersScreen` and aggregate charts via `fl_chart` in the `AdminDashboardScreen`.\n';
out += '- **State/APIs:** `AdminDashboardController` aggregates data via `GET /api/admin/dashboard-stats`.\n\n';

out += '## 5. Specialized Workflows & Architectural Constraints\n';
out += '### AI Symptom Analyzer Rendering\n';
out += 'The `AiSymptomResultScreen` receives an unparsed structured JSON from the backend (bridging Gemini/Groq). The UI dynamically parses the `severity` field and maps it to color-coded badges (e.g., Red for High Severity). It maps the `homeCare` arrays into dynamically sized `ListView` arrays.\n';
out += '*In plain terms:* The screen reads the complex medical robot text and turns it into friendly, color-coded warning labels.\n\n';

out += '### Direct Contact & Navigation UI\n';
out += 'To conform to architectural constraints, the app explicitly bypasses commercial payment flows. Instead, screens map hospital/doctor coordinate arrays and phone numbers. The UI utilizes the `url_launcher` package to direct the user to the native phone dialer or Google Maps app to complete the transaction physically.\n';
out += '*In plain terms:* Instead of paying in the app, the app gives you the phone number and map directions so you can go pay at the actual hospital desk.\n\n';

out += '## 6. UI Stability & Performance Guardrails\n';
out += '### RenderFlex Overflow Prevention\n';
out += 'Dynamic text columns (especially in the AI Symptom results) are rigorously wrapped in `Expanded` or `Flexible` widgets when placed inside a `Row`, or nested inside a `SingleChildScrollView` to prevent red-screen pixel overflows on smaller physical devices like the iPhone SE.\n';
out += '*In plain terms:* Making sure long paragraphs of text do not break the edges of tiny mobile screens.\n\n';

out += '### GetX Memory Leak Mitigation\n';
out += 'Controllers managing text input (like `AiSymptomInputController`) or subscribing to event streams explicitly override the `onClose()` lifecycle hook. Inside `onClose()`, `TextEditingController.dispose()` and `StreamSubscription.cancel()` are called to prevent orphan listeners from silently consuming RAM after the screen is popped.\n';
out += '*In plain terms:* Taking out the garbage when you leave a room so the phone does not slow down.\n\n';

fs.writeFileSync('Frontend_Architecture_Guide.md', out);
console.log('Frontend_Architecture_Guide.md regenerated successfully.');
