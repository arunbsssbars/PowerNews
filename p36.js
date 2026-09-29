const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

code = code.replace(/value: heapUsed != 'N\\/A' \? '\\$heapUsed MB Heap' : '\\$rss MB RSS',/, `value: heapUsed != 'N/A' ? '\\$heapUsed Heap' : '\\$rss RSS',`);

fs.writeFileSync('lib/screens/admin_dashboard_screen.dart', code);
console.log('Fixed MB MB');
