const fs = require('fs');
const zlib = require('zlib');

const docxPath = 'C:/D/FYP/Medi-AI_F-B-main/Medi_AI_Backend_railway/thesis/Mide-AI - Final.docx';
const buf = fs.readFileSync(docxPath);

function findEntry(name) {
  let pos = 0;
  while (pos < buf.length - 4) {
    if (buf[pos] === 0x50 && buf[pos+1] === 0x4B && buf[pos+2] === 0x03 && buf[pos+3] === 0x04) {
      const compMethod = buf.readUInt16LE(pos+8);
      const compSize = buf.readUInt32LE(pos+18);
      const fnLen = buf.readUInt16LE(pos+26);
      const extraLen = buf.readUInt16LE(pos+28);
      const fn = buf.slice(pos+30, pos+30+fnLen).toString('utf8');
      const dataStart = pos+30+fnLen+extraLen;
      if (fn === name) {
        const compData = buf.slice(dataStart, dataStart+compSize);
        if (compMethod === 8) {
          return zlib.inflateRawSync(compData).toString('utf8');
        } else {
          return compData.toString('utf8');
        }
      }
      pos = dataStart + compSize;
    } else {
      pos++;
    }
  }
  return null;
}

const xml = findEntry('word/document.xml');
if (!xml) { console.log('NOT FOUND'); process.exit(1); }

// Parse paragraphs preserving heading styles
// Extract paragraph style info
const paraRegex = /<w:p[ >][\s\S]*?<\/w:p>/g;
const styleRegex = /<w:pStyle w:val="([^"]+)"/;
const textRegex = /<w:t[^>]*>([^<]*)<\/w:t>/g;
const brRegex = /<w:br[^>]*\/>/g;

const lines = [];
let match;
while ((match = paraRegex.exec(xml)) !== null) {
  const para = match[0];
  const styleMatch = styleRegex.exec(para);
  const style = styleMatch ? styleMatch[1] : '';
  
  let text = '';
  let tm;
  const tRegex = /<w:t[^>]*>([^<]*)<\/w:t>/g;
  while ((tm = tRegex.exec(para)) !== null) {
    text += tm[1];
  }
  text = text.replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&#xA;/g,'\n').trim();
  
  if (!text) { lines.push(''); continue; }
  
  if (style.includes('Heading1') || style === '1') lines.push('\n# ' + text);
  else if (style.includes('Heading2') || style === '2') lines.push('\n## ' + text);
  else if (style.includes('Heading3') || style === '3') lines.push('\n### ' + text);
  else if (style.includes('Heading4') || style === '4') lines.push('\n#### ' + text);
  else if (style.includes('Title')) lines.push('\n# ' + text);
  else lines.push(text);
}

const output = lines.join('\n');
fs.writeFileSync('C:/D/FYP/Medi-AI_F-B-main/Medi_AI_Backend_railway/thesis/docx_raw_text.txt', output, 'utf8');
console.log('Written', output.length, 'chars,', lines.length, 'paragraphs');
// Print first 200 chars to verify
console.log('--- PREVIEW ---');
console.log(output.substring(0, 500));
