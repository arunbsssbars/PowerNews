const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

code = code.replace(/initialIndex: widget.initialTabIndex.clamp\(0, 4\),/, 'initialIndex: widget.initialTabIndex.clamp(0, 5),');

fs.writeFileSync('lib/screens/admin_dashboard_screen.dart', code);
console.log('Fixed initialTabIndex clamp');
