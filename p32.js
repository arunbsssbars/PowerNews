const fs = require('fs');
let code = fs.readFileSync('server/routes/apiRoutes.js', 'utf8');

// Replace the strict AI summary filter with a fallback map
const oldFilter = `return retained.filter(a => Boolean(a.id && aiSummaryCache[a.id] && aiSummaryCache[a.id].length >= 50));`;
const newFilter = `return retained.map(a => {
    if (a.id && aiSummaryCache[a.id] && aiSummaryCache[a.id].length >= 50) {
      return a;
    }
    // Fallback to original snippet if AI summary failed or is still processing
    return { ...a, isAiGenerated: false };
  });`;

code = code.replace(oldFilter, newFilter);
fs.writeFileSync('server/routes/apiRoutes.js', code);
console.log('Fixed apiRoutes fallback filter');
