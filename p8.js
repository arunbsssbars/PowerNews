const fs = require('fs');

let indexCode = fs.readFileSync('server/index.js', 'utf8');
indexCode = indexCode.replace(/cron\.schedule\('0 \* \* \* \*', async \(\) => {/g, "cron.schedule('*/20 * * * *', async () => {");
indexCode = indexCode.replace(/Hourly periodic feed refresh started/g, "Periodic feed refresh started");
fs.writeFileSync('server/index.js', indexCode);

let geminiCode = fs.readFileSync('server/services/geminiService.js', 'utf8');
geminiCode = geminiCode.replace(/const unsummarized = articles\.filter\(a => !aiSummaryCache\[a\.id\]\)\.slice\(0, 10\);/g, "const unsummarized = articles.filter(a => !aiSummaryCache[a.id]).slice(0, 30);");
fs.writeFileSync('server/services/geminiService.js', geminiCode);

console.log('done updating backend limits');
