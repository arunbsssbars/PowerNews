const fs = require('fs');
let code = fs.readFileSync('lib/services/auth_service.dart', 'utf8');

code = code.replace(/\/\/ --- 8\. Guest Mode Bypass ---[\s\S]*?notifyListeners\(\);\s*\}/, '');
code = code.replace(/_isGuest = true;/g, '');

fs.writeFileSync('lib/services/auth_service.dart', code);
console.log('done auth cleanup');
