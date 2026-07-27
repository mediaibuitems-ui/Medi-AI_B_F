const fs = require('fs');
const path = require('path');

const thesisPath = path.join(__dirname, 'Medi-AI_Thesis.md');
let thesisText = fs.readFileSync(thesisPath, 'utf8');

// Helper to replace sections safely
function replaceSection(marker, newText) {
    if (thesisText.includes(marker)) {
        thesisText = thesisText.replace(marker, newText);
    } else {
        console.warn(`WARNING: Could not find section to replace for marker: ${marker.substring(0, 50)}...`);
    }
}

// ==========================================
// PHASE 1: Chapter 1 (Frontmatter)
// ==========================================
const oldProblemStatement = `The Balochistan University of Information Technology, Engineering, and Management Sciences (BUITEMS) community currently lacks a centralized, user-friendly digital system for managing campus healthcare services. This absence of digital infrastructure creates several compounded issues:`;

const newProblemStatement = `The Balochistan University of Information Technology, Engineering, and Management Sciences (BUITEMS) community currently lacks a centralized, localized digital system for managing campus healthcare services. Commercial healthcare applications rely entirely on persistent cloud connections, which fail in university environments suffering from intermittent network access (such as laboratories or basement clinics). This absence of localized, offline-first digital infrastructure creates several compounded issues:`;

replaceSection(oldProblemStatement, newProblemStatement);

const oldObjectives = `AI Symptom Analysis: To develop an intelligent module that uses advanced large language models to accurately interpret user symptoms, identify potential diseases, and recommend appropriate treatments and preliminary guidance.

University Medical Person Access System: To implement a dedicated module that seamlessly connects students and staff (including faculty and administrative members) with on-campus university doctors. This system will display doctor availability and specializations, enabling easy and organized appointment booking.

Offline Medicine Alarm: To engineer a robust local notification system that allows users to securely set and manage reminders for taking medicines without requiring active internet connectivity.`;

const newObjectives = `**1. AI Symptom Analysis:** To implement a secure integration with the GroqCloud Llama-3 API to parse natural language symptom inputs and return structured JSON guidance, logging historical interactions within a MySQL database.

**2. Campus Medical Access System:** To develop an ASP.NET Core 8 REST API utilizing JWT Role-Based Access Control (RBAC) that securely connects students, faculty, and administrators with on-campus university doctors, managing pending and confirmed appointment states.

**3. Offline-First Medicine Alarm:** To engineer a hybrid synchronization system utilizing local Hive NoSQL storage and the \`flutter_local_notifications\` plugin, ensuring users receive medication reminders independently of network connectivity, and synchronizing with the central cloud database when connectivity is restored.`;

replaceSection(oldObjectives, newObjectives);

// ==========================================
// PHASE 2: Chapter 2 (Literature Review & Research Gap)
// ==========================================
const oldResearchGap = `The current body of literature highlights a pronounced gap in the development of hyper-localized, offline-first healthcare management systems designed exclusively for academic and institutional environments.`;

const newResearchGap = `#### Literature Synthesis on Security and Offline Architecture

Recent analyses of distributed systems highlight the necessity of secure API development. Research on *Context-Aware JWT Enforcement* and *Securing Microservices Architecture Using JSON* demonstrates that standard stateless tokens are vulnerable to replay attacks and payload tampering unless enforced via strict Role-Based Access Control (RBAC) and revocation middleware. Concurrently, studies comparing *NoSQL vs SQL in Healthcare Systems* (alongside implementations like *ElysianHTM*) prove that cloud-only SQL architectures fail in resource-constrained environments. These studies advocate for "offline-first" paradigms that utilize local NoSQL caches (like Hive) to ensure uninterrupted service delivery during network outages.

### RESEARCH GAP

Despite the rapid proliferation of mHealth solutions, a pronounced research gap exists in the deployment of hyper-localized, offline-first healthcare management systems specifically tailored for academic environments. Commercial systems rely entirely on persistent cloud infrastructure, rendering them inoperable during campus Wi-Fi outages. Furthermore, existing AI diagnostic tools are overly generalized and lack integration with localized clinic booking protocols. 

This thesis addresses this gap by engineering **Medi-AI**, a novel hybrid architecture that fuses a local Hive NoSQL database for offline resilience with an ASP.NET Core JWT-secured cloud backend. By specifically designing the AI triage pipeline to funnel users directly into the university's internal appointment system, Medi-AI proves the technical viability of a localized, network-resilient institutional healthcare platform.`;

replaceSection(oldResearchGap, newResearchGap);

// ==========================================
// PHASE 3: Chapter 3 (Methodology & Architecture)
// ==========================================
const oldTechStack = `The development of Medi-AI follows a strictly defined technical stack selected to ensure high performance, security, and cross-platform compatibility:

1. **Frontend:** Flutter (Dart) is utilized to generate compiled, native-performance applications for Android from a single codebase.
2. **Backend:** ASP.NET Core 8.0 serves as the primary API framework, chosen for its strongly typed C# architecture and robust middleware pipeline.
3. **Database:** MySQL is employed for relational data persistence.
4. **AI Integration:** The system integrates external LLM APIs (GroqCloud / Meta Llama 3) to process natural language queries.`;

const newTechStack = `The development of Medi-AI strictly follows an enterprise-grade technology stack:

1. **Frontend (Flutter):** Developed using Dart, leveraging **GetX** for reactive state management and route handling to cleanly separate UI from business logic.
2. **Offline Storage (Hive):** A lightweight NoSQL client-side database utilized to cache medication reminders locally, ensuring offline functionality.
3. **Background Services:** Utilizing the \`flutter_local_notifications\` OS-level plugin to trigger alarms without requiring active application execution.
4. **Backend API (ASP.NET Core 8.0):** Engineered using a Layered Architecture (Controllers, Services, Repositories). It strictly implements **JWT Role-Based Access Control (RBAC)** to secure endpoints.
5. **Database (MySQL):** Managed via Entity Framework Core (EF Core) using Code-First migrations to maintain relational schema integrity.
6. **AI Integration:** Integration with the **GroqCloud API (Meta Llama 3)** to parse user symptoms into structured JSON objects.`;

replaceSection(oldTechStack, newTechStack);

// ==========================================
// PHASE 5: Chapter 5 (Results) Tagging Dummy Data
// ==========================================
thesisText = thesisText.replace(
    `Table 5.2: Descriptive Statistics of UAT Responses`,
    `Table 5.2: Descriptive Statistics of UAT Responses\n\n> **[PLACEHOLDER: Replace this table with actual standard deviation and mean results calculated from real BUITEMS student feedback forms.]**`
);

thesisText = thesisText.replace(
    `| Create Appointment | 230ms | 180ms | 1.28x Faster |`,
    `> **[PLACEHOLDER: Replace this table with actual latency measurements (ms) collected via Apache JMeter or Postman load testing against the live production server.]**\n\n| Create Appointment | 230ms | 180ms | 1.28x Faster |`
);

// ==========================================
// PHASE 6: Chapter 6 (Future Work) & Appendix
// ==========================================
const oldFutureWork = `Future iterations of Medi-AI will focus on expanding the scope of the system. This includes adding real-time chat functionality between doctors and patients, incorporating wearable device data, and expanding the platform to serve multiple university campuses across the region.`;

const newFutureWork = `Future iterations of Medi-AI will focus on expanding the system's technical security and architectural scope:
1. **Hive AES Encryption:** Upgrading the local storage layer to utilize \`flutter_secure_storage\` to encrypt all medical records on the device, ensuring strict compliance with health data privacy regulations.
2. **Retrieval-Augmented Generation (RAG):** Enhancing the Groq API integration with vector databases to provide the LLM with localized, campus-specific medical protocols.
3. **Boot Receivers:** Implementing Android \`RECEIVE_BOOT_COMPLETED\` listeners to automatically reschedule OS-level notifications upon device reboot.
4. **Multi-Campus Scaling:** Abstracting the database architecture to support multi-tenant configurations for deployment across different university campuses.`;

replaceSection(oldFutureWork, newFutureWork);

// Update Screenshots Appendix
thesisText = thesisText.replace(
    `*Note: Replace the placeholder images below with actual screenshots of the running application before printing.*`,
    `*Note: Insert actual high-resolution screenshots captured directly from the running Flutter application (Emulator or Physical Device) here before submitting the final thesis draft.*`
);


fs.writeFileSync(thesisPath, thesisText);
console.log("Thesis alignment complete.");
