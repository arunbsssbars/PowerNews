const https = require('https');

const req = https.request({
  hostname: 'powernewsapp-backend.onrender.com',
  path: '/api/refresh',
  method: 'POST',
  headers: {
    'x-api-key': 'pwn_5a9b8c7d6e5f4g3h2i1j0'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log(data);
    process.exit(0);
  });
});

req.on('error', (err) => {
  console.error(err.message);
  process.exit(1);
});

req.end();
