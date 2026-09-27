const https = require('https');

https.get({
  hostname: 'powernewsapp-backend.onrender.com',
  path: '/api/news?limit=5',
  headers: { 'x-api-key': 'pwn_5a9b8c7d6e5f4g3h2i1j0' }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      console.log('Total News:', json.total);
      if (json.articles.length > 0) {
        console.log('Latest published:', json.articles[0].publishedAt);
        console.log('Latest title:', json.articles[0].title);
      }
    } catch(e) { console.log(data.substring(0,200)); }
    process.exit(0);
  });
}).on('error', (err) => {
  console.error(err.message);
  process.exit(1);
});
