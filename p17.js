const fs = require('fs');
let code = fs.readFileSync('server/services/geminiService.js', 'utf8');

const target = `const prompt = \`You are the Chief Editor and Senior Power Sector Intelligence Analyst for PowerNews India.
  Analyze the following article and determine whether it genuinely pertains to the Indian power, electricity, or renewable energy sector (generation, transmission, distribution, tariffs, renewables, SCADA, DISCOMs, or grid equipment).`;

const replacement = `const prompt = \`You are the Chief Editor and Senior Power Sector Intelligence Analyst for PowerNews India.
  Analyze the following article and determine whether it genuinely pertains to the Indian power, electricity, or renewable energy sector.
  
  CRITICAL INSTRUCTION: You must aggressively prioritize and extract news regarding Transmission & Distribution (T&D), State DISCOMs, Sub-stations, Smart Metering, Grid Operations, and Grid OEMs (e.g. POWERGRID, REC, PFC, Siemens, ABB, UPPCL, BESCOM). Do not let Solar/Generation news overshadow critical T&D updates.`;

code = code.replace(target, replacement);
fs.writeFileSync('server/services/geminiService.js', code);
console.log('updated gemini prompt');
