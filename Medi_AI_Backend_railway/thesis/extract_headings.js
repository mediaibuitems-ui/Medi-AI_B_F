const fs = require('fs');
const path = require('path');
const lines = fs.readFileSync('Medi-AI_Thesis.md', 'utf8').split('\n');
lines.forEach((line, index) => {
    if (line.match(/^#+\s/)) {
        console.log(`${index + 1}: ${line}`);
    }
});
