const fs = require('fs');
let code = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

const regex = /\/\/ 2\. Refresh Button[\s\S]*?Tooltip\([\s\S]*?message: 'Refresh Feeds'[\s\S]*?Icons\.sync_rounded,[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),/g;
code = code.replace(regex, "");

fs.writeFileSync('lib/screens/home_screen.dart', code);
console.log('done home_screen regex');
