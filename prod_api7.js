const https = require('https');

https.get({
  hostname: 'powernewsapp-backend.onrender.com',
  path: '/api/news?limit=100',
  headers: { 'x-api-key': 'pwn_5a9b8c7d6e5f4g3h2i1j0' }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      const missingSummary = json.articles.filter(a => !a.summary || a.summary.length < 50);
      console.log('Articles without valid summary:', missingSummary.length);
    } catch(e) {}
    process.exit(0);
  });
});
