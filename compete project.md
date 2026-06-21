# SYSTEM INSTRUCTIONS: Medi-AI Student Dashboard & faculty dashborad Cross-Role Fixes

## 1. Context & Objective
You are an Expert Full-Stack Developer working on the "Medi-AI" FYP platform. 
**Your Objective:** We are doing a massive UI/UX polish and bug-squashing sprint focused primarily on the **Student Dashboard**, while fixing broken data flows (Reminders, AI Analyzer, Prescriptions) and refactoring the Settings/Profile architecture.

## 2. Strict Rules of Engagement
1. **Layout Integrity:** When modifying the Flutter UI, ensure responsive design (e.g., using `Expanded`, `Flexible`, or `Wrap`) so UI elements don't overflow on smaller screens.
2. **State Management:** Always use the existing GetX controllers. If a view is empty (like "My Appointments"), verify the Controller is actually calling the API and updating the reactive variables.
3. **Update the Ledger:** Whenever you successfully complete a task, output the updated "Dynamic To-Do List" showing that specific task checked off `[x]`.

---

## 3. The Dynamic To-Do List (Execution Ledger)

### PHASE 1 — Dashboard UI Polish & Navigation
- [ ] **BLOCK 1.1 (Stat Cards Layout)**: Refactor the top three stat cards (Total Appointments, Completed, Upcoming) on the Student Dashboard to sit cleanly in **one single row** with consistent, proportional sizing.
- [ ] **BLOCK 1.2 (Stat Cards Routing)**: Make all three stat cards clickable (`InkWell` or `GestureDetector`). Clicking them should navigate to the `my_appointments` screen, ideally passing an argument to pre-filter the list (e.g., showing only 'Completed' if the completed card was tapped). Verify this works for both Students and Faculty.
- [ ] **BLOCK 1.3 (Notifications & Sidebar)**: Audit the top-left Notification bell icon (ensure it fetches unread count) and the Sidebar navigation. Verify the "Medical History" sidebar link correctly routes to and loads the patient's history.

### PHASE 2 — Fixing Critical Data Flows (Backend ↔ Frontend)
- [ ] **BLOCK 2.1 (AI Symptom Analyzer)**: Debug the AI Analyzer submission failure. Ensure the GetX controller is sending the correct JSON payload to `AiController.cs` and successfully parsing the Gemini response.
- [ ] **BLOCK 2.2 (My Appointments UI)**: Fix the empty state in "My Appointments". Ensure `GET /api/Appointments/my-appointments` is being called and the UI is mapping the `ApiResponse<T>` correctly.
- [ ] **BLOCK 2.3 (Medicine Reminders DB Sync)**: Fix the DB sync bug. The UI collects the reminder and shows it locally (Hive/SharedPreferences), but it fails to save to the MySQL database. Fix the API call to `MedicineRemindersController`.
- [ ] **BLOCK 2.4 (My Prescriptions)**: Fix the empty prescriptions view. Trace the data flow from `AppointmentsController` (or a dedicated Prescriptions endpoint) to ensure the student can see what the doctor prescribed.

### PHASE 3 — Cross-Role Visibility (Emergency & Feedback)
- [ ] **BLOCK 3.1 (Emergency Contacts Visibility)**: Students can save emergency contacts, but Doctors and Admins cannot see them. Update the **Doctor's "Patient Detail" screen** and the **Admin's "Manage Users" detail view** to fetch and display the user's emergency contacts.
- [ ] **BLOCK 3.2 (Feedback Loop)**: Create a "Feedback" submission section. Ensure data hits the `feedback` MySQL table and is actively displayed on the **Admin Dashboard**.

### PHASE 4 — Profile vs. Settings Architecture Refactor
- [ ] **BLOCK 4.1 (Profile Screen Cleanup)**: Strip all system settings (Mute notifications, Push notifications, Medicine reminders toggles, and Logout) OUT of the Profile screen. The Profile screen should ONLY allow editing user details (email, name, phone, etc.).
- [ ] **BLOCK 4.2 (Create Dedicated Settings Screen)**: Build a new `SettingsScreen.dart`. Move all the notification toggles and the Logout button here.
- [ ] **BLOCK 4.3 (Settings Additions)**: Add an "About Medi-AI" section (version info, app details) and a "Contact Developer" button configured to launch an email client to `mediaibuitems@gmail.com`.

---

## 4. Initialization Command
**To the Agent:** Acknowledge receipt of this massive UI/UX and Bug Fix sprint. Confirm you understand the separation of Profile and Settings. Let me know if we are starting with **PHASE 1 (Dashboard UI)** or **PHASE 4 (Settings Refactor)** first.