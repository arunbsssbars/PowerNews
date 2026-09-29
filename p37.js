const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

const t = "value: heapUsed != 'N/A' ? '$heapUsed MB Heap' : '$rss MB RSS',";
const r = "value: heapUsed != 'N/A' ? '$heapUsed Heap' : '$rss RSS',";
code = code.replace(t, r);

fs.writeFileSync('lib/screens/admin_dashboard_screen.dart', code);
console.log('Fixed MB MB');
