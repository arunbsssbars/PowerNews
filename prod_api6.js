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
      console.log('Total returned:', json.articles.length);
      const yesterday = new Date(Date.now() - 24*60*60*1000);
      const recent = json.articles.filter(a => new Date(a.publishedAt) >= yesterday);
      console.log('Articles in last 24h:', recent.length);
    } catch(e) {}
    process.exit(0);
  });
});
