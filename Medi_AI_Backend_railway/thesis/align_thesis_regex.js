const fs = require('fs');
const path = require('path');

const thesisPath = path.join(__dirname, 'Medi-AI_Thesis.md');
let thesisText = fs.readFileSync(thesisPath, 'utf8');

// Loose matching for Summary and Research Gap
const summaryRegex = /#### Summary[\s\S]*?## Chapter No\. 3/i;
const newSummary = `#### Summary and Literature Synthesis on Security and Offline Architecture

Recent analyses of distributed systems highlight the necessity of secure API development. Research on *Context-Aware JWT Enforcement* and *Securing Microservices Architecture Using JSON* demonstrates that standard stateless tokens are vulnerable to replay attacks and payload tampering unless enforced via strict Role-Based Access Control (RBAC) and revocation middleware. Concurrently, studies comparing *NoSQL vs SQL in Healthcare Systems* (alongside implementations like *ElysianHTM*) prove that cloud-only SQL architectures fail in resource-constrained environments. These studies advocate for "offline-first" paradigms that utilize local NoSQL caches (like Hive) to ensure uninterrupted service delivery during network outages.

### RESEARCH GAP

Despite the rapid proliferation of mHealth solutions, a pronounced research gap exists in the deployment of hyper-localized, offline-first healthcare management systems specifically tailored for academic environments. Commercial systems rely entirely on persistent cloud infrastructure, rendering them inoperable during campus Wi-Fi outages. Furthermore, existing AI diagnostic tools are overly generalized and lack integration with localized clinic booking protocols. 

This thesis addresses this gap by engineering **Medi-AI**, a novel hybrid architecture that fuses a local Hive NoSQL database for offline resilience with an ASP.NET Core JWT-secured cloud backend. By specifically designing the AI triage pipeline to funnel users directly into the university's internal appointment system, Medi-AI proves the technical viability of a localized, network-resilient institutional healthcare platform.

## Chapter No. 3`;

if(summaryRegex.test(thesisText)) {
    thesisText = thesisText.replace(summaryRegex, newSummary);
    console.log("Successfully replaced Literature Review Summary and Gap.");
} else {
    console.log("Failed to find Summary block.");
}


// Loose matching for Tech Stack in Chapter 3
const techStackRegex = /1\.\s\*\*Frontend:\*\*[\s\S]*?Meta Llama 3\)\s*to process natural language queries\./i;
const newTechStack = `1. **Frontend (Flutter):** Developed using Dart, leveraging **GetX** for reactive state management and route handling to cleanly separate UI from business logic.
2. **Offline Storage (Hive):** A lightweight NoSQL client-side database utilized to cache medication reminders locally, ensuring offline functionality.
3. **Background Services:** Utilizing the \`flutter_local_notifications\` OS-level plugin to trigger alarms without requiring active application execution.
4. **Backend API (ASP.NET Core 8.0):** Engineered using a Layered Architecture (Controllers, Services, Repositories). It strictly implements **JWT Role-Based Access Control (RBAC)** to secure endpoints.
5. **Database (MySQL):** Managed via Entity Framework Core (EF Core) using Code-First migrations to maintain relational schema integrity.
6. **AI Integration:** Integration with the **GroqCloud API (Meta Llama 3)** to parse user symptoms into structured JSON objects.`;

if(techStackRegex.test(thesisText)) {
    thesisText = thesisText.replace(techStackRegex, newTechStack);
    console.log("Successfully replaced Tech Stack block.");
} else {
    console.log("Failed to find Tech Stack block.");
}

// Loose matching for Future Work
const futureWorkRegex = /Future iterations of Medi-AI will focus on expanding the scope of the system\.[\s\S]*?university campuses across the region\./i;
const newFutureWork = `Future iterations of Medi-AI will focus on expanding the system's technical security and architectural scope:
1. **Hive AES Encryption:** Upgrading the local storage layer to utilize \`flutter_secure_storage\` to encrypt all medical records on the device, ensuring strict compliance with health data privacy regulations.
2. **Retrieval-Augmented Generation (RAG):** Enhancing the Groq API integration with vector databases to provide the LLM with localized, campus-specific medical protocols.
3. **Boot Receivers:** Implementing Android \`RECEIVE_BOOT_COMPLETED\` listeners to automatically reschedule OS-level notifications upon device reboot.
4. **Multi-Campus Scaling:** Abstracting the database architecture to support multi-tenant configurations for deployment across different university campuses.`;

if(futureWorkRegex.test(thesisText)) {
    thesisText = thesisText.replace(futureWorkRegex, newFutureWork);
    console.log("Successfully replaced Future Work block.");
} else {
    console.log("Failed to find Future Work block.");
}

fs.writeFileSync(thesisPath, thesisText);
console.log("Script finished.");
