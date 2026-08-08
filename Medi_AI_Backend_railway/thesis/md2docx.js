const fs = require('fs');
const { marked } = require('marked');
const HTMLtoDOCX = require('html-to-docx');

async function convert() {
    console.log("Reading Markdown...");
    const mdContent = fs.readFileSync("Medi-AI - Final (Updated).md", "utf8");
    console.log("Converting to HTML...");
    const htmlContent = marked.parse(mdContent);
    
    const fullHtml = `
    <!DOCTYPE html>
    <html>
        <head>
            <title>Medi-AI Thesis</title>
            <style>
                body { font-family: 'Times New Roman', Times, serif; font-size: 12pt; }
                h1 { font-size: 24pt; font-weight: bold; }
                h2 { font-size: 18pt; font-weight: bold; }
                h3 { font-size: 14pt; font-weight: bold; }
                table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
                td, th { border: 1px solid black; padding: 8px; }
                pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
                code { font-family: monospace; }
                blockquote { margin-left: 20px; font-style: italic; color: #555; }
            </style>
        </head>
        <body>
            ${htmlContent}
        </body>
    </html>
    `;
    
    console.log("Converting HTML to DOCX...");
    const docxBuffer = await HTMLtoDOCX(fullHtml, null, {
        table: { row: { cantSplit: true } },
        footer: true,
        pageNumber: true,
    });

    const outputPath = "Mide-AI - Final (Updated).docx";
    fs.writeFileSync(outputPath, docxBuffer);
    console.log("Successfully wrote to " + outputPath);
}

convert().catch(console.error);

