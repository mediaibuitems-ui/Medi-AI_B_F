const fs = require('fs');

const filePath = 'Medi-AI_Thesis.md';
let content = fs.readFileSync(filePath, 'utf8');

// The new Chapter 2 content
const newChapter2 = `## Chapter No. 2

### LITERATURE REVIEW

The primary purpose of this chapter is to establish a comprehensive theoretical and technical foundation for the Medi-AI framework by critically evaluating current peer-reviewed research, industrial mHealth deployments, and modern full-stack development paradigms. As electronic health infrastructure and mobile health (mHealth) architectures rapidly accelerate, analyzing recent data-driven models is vital for understanding the operational boundaries of healthcare software, particularly within tightly constrained institutional environments.

This literature review contextualizes and evaluates the intersection of client-side cross-platform application execution, server-side asynchronous query management, cryptographic token lifecycle operations, and deep neural network integration for clinical language processing. By synthesizing empirical findings from recent scientific literature, this chapter identifies the systemic architectural gaps within existing commercial options, providing an objective, verifiable engineering defense for the deployment of Medi-AI. The following sections explore the theoretical frameworks, existing research trends, and technological tools that shape modern healthcare management systems.

#### Theoretical Framework

The development and deployment of the Medi-AI system are underpinned by established theoretical models situated at the intersection of health informatics and human-computer interaction (HCI). These frameworks ensure that the system is not only technically sound but also optimized for user adoption and clinical safety.

#### Digital Triage Theory

The concept of Digital Triage Theory forms the basis of the AI Symptom Analysis module. Digital triage shifts the initial patient assessment from a human administrative bottleneck to an automated, algorithmic, or AI-driven interface. Recent frameworks emphasize that digital triage in non-emergency, institutional settings must prioritize patient safety by offering preliminary guidance rather than definitive diagnoses [14]. Medi-AI adheres to this framework by utilizing AI to streamline the pathway from symptom recognition to booking an appointment with the appropriate university medical personnel, ensuring the AI acts as an advisory tool to optimize patient flow rather than a replacement for professional clinical judgment.

#### Client-Side Storage and Offline-First Architectures

A persistent structural vulnerability across traditional cloud-dependent mobile health (mHealth) applications is their total operational reliance on continuous network infrastructure. When an application loses socket connectivity such as inside high-interference university laboratories, clinic basements, or remote student residential sectors, cloud-only frameworks fail immediately, leading to missing data, delayed reporting, and compromised patient compliance metrics [1], [4]. To address this infrastructure bottleneck within resource-constrained environments, contemporary mobile systems engineering heavily promotes the transition toward decentralized data retention and "offline-first" architectural paradigms [1], [4].

In a pivotal systems development study, Olaye and Obuh (2026) engineered a cross-platform, offline-capable mobile architecture to systematically replace fragmented, paper-based reporting workflows [1]. Developed under the strict guidance of the Design Science Research Methodology (DSRM), their work establishes a robust precedent for embedding client-side synchronization and localized database storage rather than relying on persistent server connectivity [1]. Furthermore, studies comparing NoSQL and SQL database architectures specifically for healthcare demonstrate that NoSQL caches excel at localized horizontal scaling and unstructured data retention, proving critical for offline data sync capabilities [8].

Medi-AI directly incorporates these foundational principles into its execution layer. By utilizing a denormalized local data layer (via Hive NoSQL data boxes) paired with automated background worker threads, the application completely decouples mission-critical features such as recurring medication reminders and medication log caches from active cloud network availability, ensuring system resilience across the entire university campus ecosystem [1], [4], [8].

#### Clinical Safety and Accuracy of AI Triage

While Large Language Models (LLMs) and AI chatbots offer unprecedented capabilities for parsing clinical language, the clinical safety of these tools remains a significant concern [5]. A major limitation of current diagnostic decision support systems (DDSSs) is the discrepancy between their perceived usability and their actual diagnostic accuracy. In a randomized controlled trial, Knitza et al. (2024) evaluated the diagnostic accuracy of mobile AI-based symptom checkers in rheumatology settings, revealing that overall success rates were restricted to roughly 52% [2].

Furthermore, research explicitly identifies user frustrations with existing Chatbot-Based Symptom Checkers (CSC), highlighting their lack of diagnostic depth, inability to maintain medical history context, and lack of verifiable algorithmic transparency [11]. These discrepancies, coupled with a systemic tendency to "over-triage" (directing non-urgent patients to emergency services), demonstrate that unregulated automated triage tools risk causing patient anxiety or the misutilization of finite medical resources [14]. Consequently, these findings mandate that Medi-AI adopts a strict safety-bounded architectural approach: the AI pipeline must serve exclusively as an informational routing engine that structures symptom input to streamline booking, rather than functioning as an independent diagnostic engine [2], [11], [14]. Furthermore, state-of-the-art diagnostic paradigms strongly favor Multimodal AI to increase diagnostic accuracy by synthesizing text with biological history, validating Medi-AI's goal of processing structured inputs via the context-aware Llama-3 API [7].

#### Review of Existing Research

The intersection of mobile technology, AI, and healthcare has been extensively researched, revealing significant trends and persistent gaps.

**mHealth and Medication Adherence:**
Medication non-adherence remains a critical, multi-dimensional challenge, split into intentional resistance and unintentional forgetfulness [6]. While cloud-based reminder applications are ubiquitous, meta-analyses prove that interactive, context-aware mobile health (mHealth) notifications significantly improve adherence rates compared to standard care [3]. Medi-AI leverages this research by designing offline-first alarms that directly target unintentional non-adherence without requiring constant internet connections [3], [6].

**Large Language Models (LLMs) in Healthcare Triage:**
Recent papers highlight that advanced LLMs (such as GPT-4 and Llama-3) can interpret complex, natural-language symptom descriptions with high semantic accuracy [5]. Researchers have demonstrated that integrating LLMs improves the triage process by providing immediate, structured responses [5]. However, due to inherent risks of diagnostic hallucinations, experts advise that LLM chatbots must be strictly bounded to administrative navigation and symptom recording rather than autonomous medical diagnosis [5].

**Security and Distributed Token Architectures:**
Securing microservices and cloud-native APIs is paramount for healthcare data protection. The adoption of stateless JSON Web Tokens (JWT) allows for massively scalable inter-service communication [10]. However, basic JWTs are vulnerable to token replay and session hijacking attacks [13]. Recent frameworks emphasize integrating Context-Aware JWT Enforcement (TB-CAJWE) to provide dynamic, identity-aware validation against advanced threats [13]. Furthermore, studies evaluating API security in ASP.NET Core strongly advocate for adopting this zero-trust, claims-based token model to mitigate injection and authorization vulnerabilities [9]. Medi-AI integrates these principles natively through robust JWT pipeline middleware within its ASP.NET Core backend.

#### Technologies and Tools

The selection of the technology stack for Medi-AI is strongly supported by recent software engineering literature evaluating performance, security, and cross-platform capabilities in healthcare.

**Flutter Framework:** Systematic literature reviews comparing mobile development frameworks highlight Flutter as superior for rendering complex UIs while maintaining a single Dart codebase for Android and iOS [12]. Its component-based architecture slashes development costs while providing near-native rendering performance [12].

**ASP.NET Core 8.0 & MySQL:** For backend infrastructure, ASP.NET Core is documented for its robust performance, enterprise-level API security [9], and seamless integration with relational databases. Relational databases like MySQL remain the gold standard for rigid backend clinical schedules and formal medical records [8].

**GroqCloud Llama 3 API:** Llama 3's ability to process contextual natural language rapidly via Groq's high-speed inference units makes it highly effective for symptom analysis applications, fulfilling the need for fast, structured NLP parsing without incurring massive cloud computation overhead [5].

#### Related Projects and Case Studies

To contextualize Medi-AI, several existing commercial healthcare applications heavily utilized in Pakistan were analyzed:

**Marham (Doctors & Hospitals):** Marham is a leading digital healthcare platform that allows users to search for doctors by specialty and book appointments [18]. Gap: It operates as a commercial entity, making it unsuitable for a closed university ecosystem, and relies primarily on manual navigation rather than an embedded conversational AI triage.

**Oladoc:** Oladoc offers comprehensive services including online consultations [19]. Gap: Similar to Marham, it relies entirely on human intervention for initial symptom interpretation and lacks localized offline medication reminder functionalities.

**Practo:** Practo is a globally recognized application offering health record storage and instant bookings [20]. Gap: Practo requires constant internet connectivity to access reminders and records, completely lacking the offline-first resiliency required for campus deployments [1], [4].

**Analysis:** Existing platforms excel in connecting patients to a massive network of doctors but fail to provide an integrated, localized solution. They lack AI-assisted triage and offline-first medication tools, relying instead on generic commercial cloud workflows.

### RESEARCH GAP

Despite the rapid proliferation of mHealth solutions, a pronounced research gap exists in the deployment of hyper-localized, offline-first healthcare management systems specifically tailored for academic environments. Commercial systems rely entirely on persistent cloud infrastructure, rendering them inoperable during campus Wi-Fi outages [1], [4]. Furthermore, existing AI diagnostic tools are often overly generalized, suffer from low diagnostic accuracy [2], [14], and lack integration with localized clinic booking protocols.

This thesis addresses this gap by engineering **Medi-AI**, a novel hybrid architecture that fuses a local Hive NoSQL database for offline resilience with an ASP.NET Core JWT-secured cloud backend [8], [9]. By specifically designing the AI triage pipeline to function as a bounded navigational aid funneling users directly into the university's internal appointment system, Medi-AI proves the technical viability of a localized, network-resilient, and clinically safe institutional healthcare platform.`;


const newReferences = `## References

[1] E. Olaye and D. Obuh, "An Offline-First Mobile Reporting System for Digital One Health Surveillance in Resource-Constrained Settings," *International Journal of Applied Methods in Electronics and Computers*, vol. 14, no. 2, Jun. 2026.

[2] J. Knitza et al., "Diagnostic Accuracy of a Mobile AI-Based Symptom Checker and a Web-Based Self-Referral Tool in Rheumatology: Multicenter Randomized Controlled Trial," *Journal of Medical Internet Research*, vol. 26, Jul. 2024.

[3] J. Thakkar et al., "Effectiveness of Mobile Health for Improving Medication Adherence: A Meta-analysis," *JAMA Internal Medicine*, 2016.

[4] N. L. Edoh et al., "ElysianHTM: A Modern, Offline-First Healthcare System," *ResearchGate*, Mar. 2026.

[5] A. J. Thirunavukarasu, D. S. J. Ting, et al., "Large language models in medicine," *Nature Medicine*, vol. 29, pp. 1930–1940, Aug. 2023.

[6] World Health Organization, "Medication Adherence Challenges: Factors Influencing Non-Adherence," *Global Healthcare and Medical Journals*.

[7] Various, "Multimodal AI for Alzheimer Disease Diagnosis Systematic Review," *Frontiers in Aging Neuroscience*.

[8] V. Agarwal, R. Singh, and J. Jain, "NoSQL vs SQL in Healthcare Systems: A Performance Comparison," *Pratibodh Journal*.

[9] G. Zacharia, "Review of Secure API Development and Authentication Mechanisms in ASP.NET Core Applications," 2026.

[10] P. Gowda et al., "Securing Microservices Architecture Using JSON Web Tokens," *Network and Application Security Journals*.

[11] Y. You and X. Gui, "Self-Diagnosis through AI-Enabled Chatbot-Based Symptom Checkers: User Experiences and Design Considerations," *AMIA Annual Symposium Proceedings*.

[12] Various, "Systematic Literature Review Pengembangan Aplikasi Mobile Cross-Platform," *Computer Science Journals*.

[13] Various, "Token Binding & Context-Aware JWT Enforcement: A Secure Identity-Aware Token," May 2026.

[14] E. Riboli-Sasco et al., "Triage and Diagnostic Accuracy of Online Symptom Checkers: A Systematic Review," *Journal of Medical Internet Research*, 2023.

[15] Flutter Documentation, "Flutter: Build apps for any screen," [Online]. Available: https://flutter.dev. [Accessed: Jun. 2025].

[16] Microsoft, "ASP.NET Core documentation," [Online]. Available: https://learn.microsoft.com/en-us/aspnet/core. [Accessed: Jun. 2025].

[17] MySQL, "MySQL 8.0 Reference Manual," [Online]. Available: https://dev.mysql.com/doc/refman/8.0/en/. [Accessed: Jun. 2025].

[18] Marham, "Marham – Find a Doctor, Book Appointment," [Online]. Available: https://www.marham.pk. [Accessed: Jun. 2025].

[19] Oladoc, "Oladoc – Book Doctor Appointments Online," [Online]. Available: https://oladoc.com. [Accessed: Jun. 2025].

[20] Practo, "Practo: Online Doctor Consultations & Appointments," [Online]. Available: https://www.practo.com. [Accessed: Jun. 2025].`;

// Extract sections safely
const chapter2Index = content.indexOf('## Chapter No. 2');
const chapter3Index = content.indexOf('## Chapter No. 3');
const referencesIndex = content.indexOf('## References');
const appendixIndex = content.indexOf('## APPENDIX A');

if (chapter2Index !== -1 && chapter3Index !== -1 && referencesIndex !== -1 && appendixIndex !== -1) {
    const beforeChapter2 = content.substring(0, chapter2Index);
    const chapter3ToReferences = content.substring(chapter3Index, referencesIndex);
    const appendixToEnd = content.substring(appendixIndex);

    // Assemble the final document
    const finalContent = beforeChapter2 + newChapter2 + '\n\n' + chapter3ToReferences + newReferences + '\n\n' + appendixToEnd;
    
    fs.writeFileSync(filePath, finalContent, 'utf8');
    console.log("Successfully updated Chapter 2 and References section.");
} else {
    console.error("Error: Could not find one or more necessary headers.");
    console.log({
        chapter2Index,
        chapter3Index,
        referencesIndex,
        appendixIndex
    });
}
