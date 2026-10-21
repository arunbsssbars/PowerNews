// Entrypoint proxy to server/index.js
const server = require('./server/index.js');

module.exports = server;

// If started as standalone process via CLI (e.g. npm start / node news-aggregator.js)
if (require.main === module) {
  server.startServer();
}
