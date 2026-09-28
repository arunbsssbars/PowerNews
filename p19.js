const fs = require('fs');

let authCode = fs.readFileSync('lib/services/auth_service.dart', 'utf8');

authCode = authCode.replace(/bool _isGuest = false;/g, '');
authCode = authCode.replace(/bool get isGuest => _isGuest;/g, '');
authCode = authCode.replace(/_isGuest = prefs\.getBool\('auth_is_guest'\) \?\? false;/g, '');
authCode = authCode.replace(/_isGuest = false;/g, '');
authCode = authCode.replace(/await prefs\.setBool\('auth_is_guest', true\);/g, '');
authCode = authCode.replace(/await prefs\.setBool\('auth_is_guest', false\);/g, '');
authCode = authCode.replace(/await prefs\.remove\('auth_is_guest'\);/g, '');
authCode = authCode.replace(/\/\/ --- 8\. Guest Mode Bypass ---\s+void continueAsGuest\(\) async \{\s+final prefs = await SharedPreferences\.getInstance\(\);\s+notifyListeners\(\);\s+\}/g, '');

fs.writeFileSync('lib/services/auth_service.dart', authCode);

let loginCode = fs.readFileSync('lib/screens/login_signup_screen.dart', 'utf8');
const guestBlockRegex = /\/\/ Guest Bypass Option[\s\S]*?TextButton\.icon\([\s\S]*?onPressed: \(\) \{[\s\S]*?continueAsGuest\(\);[\s\S]*?_proceedToApp\(\);[\s\S]*?\},[\s\S]*?icon:[\s\S]*?label:[\s\S]*?Explore as Guest without Signing In[\s\S]*?\),[\s\S]*?\),/;
loginCode = loginCode.replace(guestBlockRegex, '');
fs.writeFileSync('lib/screens/login_signup_screen.dart', loginCode);

let mainCode = fs.readFileSync('lib/main.dart', 'utf8');
mainCode = mainCode.replace(/&& !auth\.isGuest/g, '');
fs.writeFileSync('lib/main.dart', mainCode);

console.log('removed guest auth');
