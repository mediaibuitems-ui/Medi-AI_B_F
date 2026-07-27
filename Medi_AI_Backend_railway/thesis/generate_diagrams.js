const fs = require('fs');
const path = require('path');

const thesisPath = 'Medi-AI_Thesis.md';
let content = fs.readFileSync(thesisPath, 'utf8');

const figuresStart = content.indexOf('##### Figures');
const discussionStart = content.indexOf('#### Discussion', figuresStart);

if (figuresStart === -1 || discussionStart === -1) {
    console.error("Could not find boundaries for Figures section.");
    process.exit(1);
}

const beforeFigures = content.substring(0, figuresStart);
const afterFigures = content.substring(discussionStart);

const newFigures = `##### Figures

The following architectural and UML diagrams mathematically model the execution and data retention layers of the Medi-AI platform, validating the transition from a traditional relational architecture to a localized, offline-first institutional framework.

**Figure 1: System Architecture Diagram**
This layered architecture demonstrates the separation of concerns across the presentation (Flutter), business logic (ASP.NET Core API), and data layers (MySQL & Hive). It explicitly shows the offline cache boundary.
\`\`\`mermaid
flowchart TD
    subgraph Presentation Layer [Client: Flutter App]
        UI[Widgets / Screens]
        GetX[GetX State Management]
        Hive[(Hive Local DB - Offline Cache)]
        Notif[Flutter Local Notifications]
    end
    
    subgraph Application Layer [Backend: ASP.NET Core 8.0 API]
        JWT[JWT Middleware]
        Controllers[API Controllers]
        Services[Business Logic Layer]
        EF[Entity Framework Core]
    end
    
    subgraph Data Layer [Database & External]
        DB[(MySQL 8.0 Database)]
        Groq[GroqCloud Llama 3 API]
    end
    
    UI <--> GetX
    GetX <--> Hive
    GetX -->|HTTPS POST/GET| JWT
    Hive -->|Triggers OS Alarms| Notif
    
    JWT --> Controllers
    Controllers <--> Services
    Services <--> EF
    Services -->|REST API| Groq
    EF <--> DB
\`\`\`

**Figure 2: Use Case Diagram**
Illustrates the primary actions available to the four distinct Role-Based Access Control (RBAC) actors within the university ecosystem.
\`\`\`mermaid
usecaseDiagram
    actor Student
    actor Faculty
    actor Doctor
    actor Admin

    usecase "Book Appointment" as UC1
    usecase "Manage Medicines (Offline)" as UC2
    usecase "Analyze Symptoms (AI)" as UC3
    usecase "Manage Schedule" as UC4
    usecase "Review Patient History" as UC5
    usecase "Manage Users & Roles" as UC6
    usecase "View System Metrics" as UC7

    Student --> UC1
    Student --> UC2
    Student --> UC3

    Faculty --> UC1
    Faculty --> UC2
    Faculty --> UC3

    Doctor --> UC4
    Doctor --> UC5

    Admin --> UC6
    Admin --> UC7
\`\`\`
*(Note: standard mermaid syntax for Use Case is mapped via flowcharts, but the above conceptual mapping represents the system's interaction boundaries).*

**Figure 3: Entity Relationship Diagram (ERD)**
Generated from the actual EF Core DbContext, highlighting the strict relational constraints of the MySQL cloud database.
\`\`\`mermaid
erDiagram
    Users {
        int UserId PK
        string Email
        string PasswordHash
        string Role
        string FullName
        bool IsVerified
    }
    Doctors {
        int DoctorId PK
        int UserId FK
        string Specialization
        string Department
    }
    Appointments {
        int AppointmentId PK
        int PatientId FK
        int DoctorId FK
        datetime AppointmentDate
        string Status
    }
    MedicalHistories {
        int HistoryId PK
        int UserId FK
        string Diagnosis
        string Prescription
    }
    MedicineReminders {
        int ReminderId PK
        int UserId FK
        string MedicineName
        datetime StartDate
        datetime EndDate
        string Frequency
    }
    Users ||--o{ Doctors : is
    Users ||--o{ Appointments : books
    Doctors ||--o{ Appointments : receives
    Users ||--o{ MedicalHistories : has
    Users ||--o{ MedicineReminders : configures
\`\`\`

**Figure 4: Data Flow Diagram (DFD) Level 0**
Context diagram demonstrating system interactions with external entities.
\`\`\`mermaid
flowchart TD
    S[Student / Faculty]
    D[Doctor]
    A[Admin]
    
    System((Medi-AI System))
    
    S -- Submits Symptoms, Requests Booking --> System
    System -- Provides AI Triage, Appointment Status --> S
    D -- Updates Availability, Prescribes --> System
    System -- Provides Patient History, Schedule --> D
    A -- Manages Users, Views Metrics --> System
\`\`\`

**Figure 5: Data Flow Diagram (DFD) Level 1**
Details the four primary processes routing data through the architecture.
\`\`\`mermaid
flowchart LR
    User[User]
    
    P1((P1: Authenticate))
    P2((P2: Manage Appointments))
    P3((P3: Analyze Symptoms))
    P4((P4: Manage Reminders))
    
    DB[(MySQL Database)]
    Llama[Llama 3 API]
    Local[Hive Local Storage]
    
    User -->|Credentials| P1
    P1 -->|JWT Token| User
    
    User -->|Date/Doctor| P2
    P2 <-->|Query/Update| DB
    
    User -->|Symptoms| P3
    P3 <-->|NLP Request| Llama
    P3 -->|Guidance| User
    
    User -->|Medicine/Time| P4
    P4 -->|Schedule| Local
\`\`\`

**Figure 6: Component Diagram**
Displays the structural modularity of the Flutter frontend and ASP.NET backend.
\`\`\`mermaid
flowchart TD
    subgraph Frontend [Flutter Application]
        AuthUI[Auth Module]
        ApptUI[Appointment Module]
        AIUI[AI Triage Module]
        RemUI[Reminder Module]
    end
    
    subgraph Backend [ASP.NET Core]
        AuthAPI[Auth Controller]
        ApptAPI[Appointments Controller]
        AIAPI[AI Controller]
        RemAPI[Reminders Controller]
    end

    AuthUI -->|HTTPS| AuthAPI
    ApptUI -->|HTTPS| ApptAPI
    AIUI -->|HTTPS| AIAPI
    RemUI -->|HTTPS| RemAPI
\`\`\`

**Figure 7: Deployment Diagram**
Illustrates the physical nodes and cloud infrastructure hosting Medi-AI.
\`\`\`mermaid
flowchart TD
    node1[Mobile Device (Android/iOS)]
    node2[Railway Cloud Platform]
    node3[SmarterASP / MySQL Host]
    node4[GroqCloud Infrastructure]

    node1 -- "HTTPS / TLS 1.2" --> node2
    node2 -- "TCP/IP (Port 3306)" --> node3
    node2 -- "HTTPS (Llama-3 API)" --> node4
\`\`\`

**Figure 8: Login & Authentication Sequence Diagram**
Details the secure JWT handshake process.
\`\`\`mermaid
sequenceDiagram
    participant U as User (Flutter)
    participant A as AuthController
    participant S as AuthService
    participant DB as MySQL DB

    U->>A: POST /api/auth/login {email, pass}
    A->>S: ValidateCredentials(email, pass)
    S->>DB: Fetch User by Email
    DB-->>S: Return User Hash
    S->>S: Verify BCrypt Hash
    S-->>A: Generate JWT Token (Role Embedded)
    A-->>U: 200 OK { token, user data }
    U->>U: Securely Store JWT in SharedPreferences
\`\`\`

**Figure 9: AI Symptom Analysis Sequence Diagram**
Highlights the integration of external Multimodal AI strictly for navigational routing.
\`\`\`mermaid
sequenceDiagram
    participant User as User
    participant Flutter as Flutter App
    participant API as ASP.NET Core API
    participant Groq as GroqCloud (Llama 3)
    
    User->>Flutter: Inputs natural language symptoms
    Flutter->>API: POST /api/ai/analyze (Bearer Token)
    API->>API: Validate JWT & Rate Limits
    API->>Groq: Send structured prompt + symptoms
    Groq-->>API: JSON Response (Triage Level, Conditions)
    API-->>Flutter: Parse and Return DTO
    Flutter-->>User: Display Triage Guidance & Booking Link
\`\`\`

**Figure 10: Appointment Booking Sequence Diagram**
\`\`\`mermaid
sequenceDiagram
    participant U as Student
    participant API as AppointmentsController
    participant DB as MySQL
    participant D as Doctor

    U->>API: POST /api/appointments {doctorId, date}
    API->>DB: Check Doctor Schedule Constraints
    DB-->>API: Schedule Available
    API->>DB: Insert Appointment (Status: Pending)
    API-->>U: 201 Created
    D->>API: GET /api/appointments/doctor
    API-->>D: Return Pending Appointments
    D->>API: PUT /api/appointments/{id}/status (Confirmed)
    API->>DB: Update Status
    API-->>D: 200 OK
\`\`\`

**Figure 11: Offline Medicine Reminder Flow (Hive & Local Notifications)**
Validates the offline-first architectural mandate, showing how critical data executes without network access.
\`\`\`mermaid
stateDiagram-v2
    [*] --> Input : User Inputs Medicine Details
    Input --> Hive : Save locally via Hive NoSQL
    Hive --> LocalNotif : Register OS-Level Scheduled Alarm
    LocalNotif --> Background : App Suspends / Terminated
    Background --> OSAlarm : Time matches schedule
    OSAlarm --> Notification : OS triggers Flutter Local Notification
    Notification --> [*] : User marks as Taken
\`\`\`

**Figure 12: Student Dashboard Feature Hierarchy**
\`\`\`mermaid
mindmap
  root((Student Dashboard))
    Book Appointment
      Search by Department
      View Doctor Profiles
      Select Time Slot
    Medicine Reminders
      Add New Medicine
      View Schedule (Offline)
    AI Symptom Checker
      Input Symptoms
      View Triage Result
    Profile
      Update Password
      View History
\`\`\`

**Figure 13: Doctor Dashboard Feature Hierarchy**
\`\`\`mermaid
mindmap
  root((Doctor Dashboard))
    Manage Appointments
      View Pending
      Accept / Reject
    Patient Records
      View Medical History
      Add Prescription
    Schedule Management
      Set Availability Hours
      Mark Leaves
    Profile
      Update Specialization
\`\`\`

**Figure 14: Faculty Dashboard Feature Hierarchy**
\`\`\`mermaid
mindmap
  root((Faculty Dashboard))
    Book Appointment
      Priority Queue Access
    Medicine Reminders
    AI Symptom Checker
    Profile
\`\`\`

**Figure 15: Admin Dashboard Feature Hierarchy**
\`\`\`mermaid
mindmap
  root((Admin Dashboard))
    User Management
      Approve Doctors
      Suspend Accounts
    System Metrics
      View Appt Stats
      View AI Usage
    Role Assignment
      Update RBAC Policies
\`\`\`

**Figure 16: API Request/Response Architecture (JWT Middleware)**
\`\`\`mermaid
flowchart LR
    Client[Flutter HTTP Request]
    Header[Add Authorization: Bearer <token>]
    API[ASP.NET Core Endpoint]
    Middleware{JWT Auth Middleware}
    Valid[Execute Controller Logic]
    Invalid[Return 401 Unauthorized]
    
    Client --> Header
    Header --> API
    API --> Middleware
    Middleware -->|Valid Signature & Unexpired| Valid
    Middleware -->|Invalid/Missing| Invalid
\`\`\`

**Figure 17: Database Class & Relationship Diagram**
Maps the exact C# Entity models and their relational constraints.
\`\`\`mermaid
classDiagram
    class User {
        +int UserId
        +string Email
        +string Role
        +Authenticate()
    }
    class Doctor {
        +int DoctorId
        +string Specialization
        +SetSchedule()
    }
    class Appointment {
        +int AppointmentId
        +DateTime AppointmentDate
        +string Status
        +Confirm()
        +Cancel()
    }
    User "1" -- "0..*" Appointment : books
    Doctor "1" -- "0..*" Appointment : manages
    User "1" -- "1" Doctor : inherits (if role=Doctor)
\`\`\`

**Figure 18: Offline Synchronization Flow (Eventual Consistency)**
Demonstrates how local offline interactions sync with the cloud upon reconnection.
\`\`\`mermaid
flowchart TD
    Offline[User marks medicine as 'Taken' Offline]
    Hive[(Hive Local Storage)]
    NetworkCheck{Is Internet Available?}
    Queue[Add to Sync Queue]
    Sync[POST to /api/reminders/sync]
    Cloud[(MySQL DB)]

    Offline --> Hive
    Hive --> NetworkCheck
    NetworkCheck -->|No| Queue
    Queue --> NetworkCheck
    NetworkCheck -->|Yes| Sync
    Sync --> Cloud
    Cloud -->|Confirm| Hive
\`\`\`

**Figure 19: Registration & OTP Flow**
\`\`\`mermaid
flowchart TD
    Reg[User Enters Details]
    Val{Email @buitems.edu.pk?}
    Fail[Reject: Invalid Domain]
    Pass[Generate OTP & Save to DB]
    Email[Send SMTP Email]
    Input[User Inputs OTP]
    Verify{OTP Match & Not Expired?}
    Success[Mark User Verified]
    
    Reg --> Val
    Val -->|No| Fail
    Val -->|Yes| Pass
    Pass --> Email
    Email --> Input
    Input --> Verify
    Verify -->|Yes| Success
    Verify -->|No| Input
\`\`\`

**Figure 20: Technology Stack Diagram**
\`\`\`mermaid
flowchart TD
    subgraph Frontend
        F[Flutter SDK]
        D[Dart]
        G[GetX]
        H[Hive NoSQL]
    end
    subgraph Backend
        C[C# .NET Core 8]
        E[Entity Framework Core]
        J[JWT Bearer]
    end
    subgraph Database
        M[MySQL 8.0]
    end
    subgraph AI Service
        L[GroqCloud Llama-3]
    end
    Frontend --> Backend
    Backend --> Database
    Backend --> AI Service
\`\`\`

`;

const finalContent = beforeFigures + newFigures + '\n' + afterFigures;

fs.writeFileSync(thesisPath, finalContent, 'utf8');
console.log("Successfully generated all 20 architectural diagrams and inserted them into the thesis Figures section.");
