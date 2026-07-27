const fs = require('fs');
const path = require('path');

async function extract() {
    try {
        const pdf = require(path.join(__dirname, '../Medi_AI_Backend_railway/thesis/node_modules/pdf-parse'));
        const file = "An Offline-First Mobile Reporting System for Digital One Health Surveillance in Resource-Constrained Settings.pdf";
        const dataBuffer = fs.readFileSync(path.join(__dirname, file));
        
        pdf(dataBuffer).then(function(data) {
            console.log("=== BEGIN PDF TEXT ===");
            console.log(data.text.substring(0, 3000)); // First 3000 chars should cover title and abstract
            console.log("=== END PDF TEXT ===");
        }).catch(err => {
            console.error("PDF-PARSE ERROR:", err);
        });
    } catch(e) {
        console.error("REQUIRE ERROR:", e);
    }
}
extract();
