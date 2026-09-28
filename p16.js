const fs = require('fs');

// 1. constants.js
let consts = fs.readFileSync('server/config/constants.js', 'utf8');
consts = consts.replace(/7 \* 24 \* 60 \* 60 \* 1000/g, '30 * 24 * 60 * 60 * 1000');
consts = consts.replace(/7 days/g, '30 days');
fs.writeFileSync('server/config/constants.js', consts);

// 2. classifierService.js
let classifier = fs.readFileSync('server/services/classifierService.js', 'utf8');
classifier = classifier.replace(/filterArticlesRetention7Days/g, 'filterArticlesRetention30Days');
fs.writeFileSync('server/services/classifierService.js', classifier);

// 3. apiRoutes.js
let api = fs.readFileSync('server/routes/apiRoutes.js', 'utf8');
api = api.replace(/filterArticlesRetention7Days/g, 'filterArticlesRetention30Days');
fs.writeFileSync('server/routes/apiRoutes.js', api);

// 4. rssService.js
let rss = fs.readFileSync('server/services/rssService.js', 'utf8');
rss = rss.replace(/filterArticlesRetention7Days/g, 'filterArticlesRetention30Days');
rss = rss.replace(/sevenDayArticles/g, 'thirtyDayArticles');
rss = rss.replace(/7-day/g, '30-day');
fs.writeFileSync('server/services/rssService.js', rss);

console.log('updated 30 days');
