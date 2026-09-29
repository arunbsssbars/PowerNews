const fs = require('fs');
let code = fs.readFileSync('server/routes/apiRoutes.js', 'utf8');

const t = `  return retained.map(a => {
    if (a.id && aiSummaryCache[a.id] && aiSummaryCache[a.id].length >= 50) {
      return a;
    }
    // Fallback to original snippet if AI summary failed or is still processing
    return { ...a, isAiGenerated: false };
  });`;
const r = `  // Only serve articles that have successfully completed the 60-word Gemini pipeline
  return retained.filter(a => Boolean(a.id && aiSummaryCache[a.id] && aiSummaryCache[a.id].length >= 50));`;

code = code.replace(t, r);
fs.writeFileSync('server/routes/apiRoutes.js', code);
console.log('Reverted fallback to strict filter');
