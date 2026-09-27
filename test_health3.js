const https = require('https');

https.get('https://powernewsapp-backend.onrender.com/api/health', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log(data);
    process.exit(0);
  });
});
