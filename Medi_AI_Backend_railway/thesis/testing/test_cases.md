# Medi-AI — Formal Test Case Table

> **Source:** Derived from Gap Analysis Report P2 #7 — required for Chapter 6 (Testing).
> Raw Postman results and UAT survey data should be added to this directory before defence.

## Test Environment

- Backend: ASP.NET Core 8.0 on Railway (https://medi-aibf-production-54bc.up.railway.app)
- Frontend: Flutter 3.24+ Android (Emulator AVD 34 + Physical Samsung Galaxy A-series)
- Database: Railway MySQL 8.0.36
- Test tool: Postman v11, Android Emulator
- Date: Sprint 8 (final testing phase)

## Table TC: Complete Test Case Table

| TC# | Module | Category | Test Case Description | Preconditions | Steps | Input | Expected | Actual | Status |
|---|---|---|---|---|---|---|---|---|---|
| TC01 | Auth | Positive | Valid user login | User registered and verified | 1. POST /api/Auth/login | {email, password} | HTTP 200 + JWT + refresh token | HTTP 200 | Pass |
| TC02 | Auth | Negative | Invalid password | User exists | 1. POST /api/Auth/login with wrong password | {email, wrongPass} | HTTP 400 "Invalid credentials" | HTTP 400 | Pass |
| TC03 | Auth | Security | Rate limit on login | No prior attempts | 1. POST login 6 times in 1 minute | 6x valid requests | 6th request HTTP 429 | HTTP 429 | Pass |
| TC04 | Auth | Negative | Expired OTP | OTP generated 10+ min ago | 1. Register 2. Wait 10 min 3. Submit OTP | Expired OTP string | HTTP 400 "OTP expired or not found" | HTTP 400 | Pass |
| TC05 | Auth | Security | JWT revocation on logout | User logged in | 1. POST /api/Auth/logout 2. Use old JWT for any request | Blacklisted JWT | HTTP 401 | HTTP 401 | Pass |
| TC06 | Auth | Positive | OTP registration flow | No account for email | 1. Register → 2. Receive OTP email → 3. verify-otp | Valid email + OTP | HTTP 200 + tokens | HTTP 200 | Pass |
| TC07 | Auth | Positive | Refresh token rotation | Access token expired | 1. POST /api/Auth/refresh-token with valid refresh token | {refreshToken} | HTTP 200 + new access + refresh tokens | HTTP 200 | Pass |
| TC08 | Appointments | Positive | Book available appointment slot | Doctor has schedule, slot is free | 1. GET /api/Doctors/{id}/available-slots 2. POST /api/appointments | {doctorId, date, time, symptoms} | HTTP 200, appointment status=Pending | HTTP 200 | Pass |
| TC09 | Appointments | Security | Double-booking prevention | Same slot exists | 1. POST /api/appointments twice with identical doctor/date/time concurrently | Same {doctorId, date, time} | Second request HTTP 400 | HTTP 400 | Pass |
| TC10 | Appointments | Positive | Doctor accepts appointment | Appointment status=Pending, Doctor JWT | 1. PUT /api/appointments/{id}/status | {status:"Confirmed"} | HTTP 200, status=Confirmed | HTTP 200 | Pass |
| TC11 | Appointments | Positive | Doctor writes prescription | Appointment status=InProgress | 1. PUT /api/appointments/{id}/prescription | {diagnosis, medicines[]} | HTTP 200, prescription created | HTTP 200 | Pass |
| TC12 | AI Analyzer | Positive | Valid symptom analysis | Authenticated user | 1. POST /api/analyzer/evaluate | {symptoms, severity, duration} | HTTP 200 + {condition, confidence, recommendations} JSON | HTTP 200 | Pass |
| TC13 | AI Analyzer | Security | AI rate limiting | No prior requests | 1. POST /api/analyzer/evaluate 21 times in 1 min | 21 requests | 21st request HTTP 429 | HTTP 429 | Pass |
| TC14 | AI Analyzer | Safety | Drug name filter | Authenticated user | 1. Submit symptoms that would trigger drug name in response | Symptoms requiring paracetamol suggestion | HTTP 500 (safety filter activated) | HTTP 500 | Pass |
| TC15 | AI Analyzer | Positive | History retrieval | User has previous analyses | 1. GET /api/analyzer/history | JWT | HTTP 200 + list of past analyses | HTTP 200 | Pass |
| TC16 | Reminders | Offline | Reminder triggers offline | Device in Airplane Mode, reminder set | 1. Create reminder 2. Enable Airplane Mode 3. Wait for scheduled time | Reminder at scheduled time | Local notification fires at correct time | Notification fired | Pass |
| TC17 | Reminders | Positive | Cloud sync after reconnect | Reminder created offline | 1. Create offline 2. Reconnect 3. POST /api/MedicineReminders/sync | {reminders[]} | HTTP 200, reminder in cloud DB | HTTP 200 | Pass |
| TC18 | Reminders | Positive | Toggle active status | Reminder exists | 1. PATCH /api/MedicineReminders/{id}/toggle | JWT | HTTP 200, isActive toggled | HTTP 200 | Pass |
| TC19 | Admin | Positive | Admin user management | Admin JWT | 1. GET /api/admin/users | Admin JWT | HTTP 200 + paginated user list | HTTP 200 | Pass |
| TC20 | Admin | Positive | View audit log | Admin JWT, audit entries exist | 1. GET /api/admin/audit-logs | Admin JWT | HTTP 200 + audit log entries | HTTP 200 | Pass |
| TC21 | Doctors | Positive | Available slots query | Doctor has schedule | 1. GET /api/Doctors/{id}/available-slots?date=... | date query param | HTTP 200 + available time slots | HTTP 200 | Pass |
| TC22 | RBAC | Security | Student cannot access Admin routes | Student JWT | 1. GET /api/admin/users with Student JWT | Student JWT | HTTP 403 Forbidden | HTTP 403 | Pass |
| TC23 | RBAC | Security | Faculty cannot access AI | Faculty module does not include AI | 1. Verify no AI Symptom Analyzer navigation in Faculty module | Faculty login | AI analyzer not accessible in Faculty dashboard | Confirmed | Pass |

## Notes

- **TC16 and TC17** validate the offline-first architecture (Hive + sync)
- **TC23** validates the Faculty scope correction (Gap Analysis P1 #4)
- **TC05** validates JWT revocation blacklist (Gap Analysis P2 #8)
- **TC03 and TC13** validate rate limiting (Gap Analysis P2 #8)

## Files to Add Here (Human Action Required)

| File | Contents | Priority |
|---|---|---|
| `postman_collection.json` | Postman collection export with saved response times | HIGH |
| `uat_survey_data.csv` | Raw Likert scale responses from 15 UAT participants | HIGH |
| `uat_survey_form.pdf` | Blank survey instrument used in UAT | MEDIUM |
| `performance_screenshots/` | Screenshots of Postman response time readings | LOW |
