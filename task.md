# The Dynamic To-Do List (Execution Ledger)

### PHASE 1 — Dashboard UI Polish & Navigation
- [x] **BLOCK 1.1 (Stat Cards Layout)**: Refactor the top three stat cards (Total Appointments, Completed, Upcoming) on the Student Dashboard to sit cleanly in **one single row** with consistent, proportional sizing.
- [x] **BLOCK 1.2 (Stat Cards Routing)**: Make all three stat cards clickable (`InkWell` or `GestureDetector`). Clicking them should navigate to the `my_appointments` screen, ideally passing an argument to pre-filter the list (e.g., showing only 'Completed' if the completed card was tapped). Verify this works for both Students and Faculty.
- [x] **BLOCK 1.3 (Notifications & Sidebar)**: Audit the top-left Notification bell icon (ensure it fetches unread count) and the Sidebar navigation. Verify the "Medical History" sidebar link correctly routes to and loads the patient's history.

### PHASE 2 — Fixing Critical Data Flows (Backend ↔ Frontend)
- [x] **BLOCK 2.1 (AI Symptom Analyzer)**: Debug the AI Analyzer submission failure. Ensure the GetX controller is sending the correct JSON payload to `AiController.cs` and successfully parsing the Gemini response.
- [x] **BLOCK 2.2 (My Appointments UI)**: Fix the empty state in "My Appointments". Ensure `GET /api/Appointments/my-appointments` is being called and the UI is mapping the `ApiResponse<T>` correctly.
- [x] **BLOCK 2.3 (Medicine Reminders DB Sync)**: Fix the DB sync bug. The UI collects the reminder and shows it locally (Hive/SharedPreferences), but it fails to save to the MySQL database. Fix the API call to `MedicineRemindersController`.
- [x] **BLOCK 2.4 (My Prescriptions)**: Fix the empty prescriptions view. Trace the data flow from `AppointmentsController` (or a dedicated Prescriptions endpoint) to ensure the student can see what the doctor prescribed.

### PHASE 3 — Cross-Role Visibility (Emergency & Feedback)
- [x] **BLOCK 3.1 (Emergency Contacts Visibility)**: Students can save emergency contacts, but Doctors and Admins cannot see them. Update the **Doctor's "Patient Detail" screen** and the **Admin's "Manage Users" detail view** to fetch and display the user's emergency contacts.
- [x] **BLOCK 3.2 (Feedback Loop)**: Create a "Feedback" submission section. Ensure data hits the `feedback` MySQL table and is actively displayed on the **Admin Dashboard**.

### PHASE 4 — Profile vs. Settings Architecture Refactor
- [x] **BLOCK 4.1 (Profile Screen Cleanup)**: Strip all system settings (Mute notifications, Push notifications, Medicine reminders toggles, and Logout) OUT of the Profile screen. The Profile screen should ONLY allow editing user details (email, name, phone, etc.).
- [x] **BLOCK 4.2 (New Settings Screen)**: Create a dedicated `SettingsScreen` (with its own Controller and Route) accessible from the Student Dashboard. Move the toggles, 'About App', 'Contact Developer', and 'Logout' button here.
- [x] **BLOCK 4.3 (Settings Additions)**: Add an "About Medi-AI" section (version info, app details) and a "Contact Developer" button configured to launch an email client to `mediaibuitems@gmail.com`.