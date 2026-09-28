const fs = require('fs');
let code = fs.readFileSync('lib/services/auth_service.dart', 'utf8');

const target = `  // --- 8. Guest Mode Bypass ---
  void continueAsGuest() async {
    
    final prefs = await SharedPreferences.getInstance();
    
    notifyListeners();
  }`;

code = code.replace(target, '');
fs.writeFileSync('lib/services/auth_service.dart', code);
console.log('done auth');
