const fs = require('fs');
let code = fs.readFileSync('lib/services/auth_service.dart', 'utf8');

const newMethods = `
  // --- Reload User (for email verification) ---
  Future<void> reloadUser() async {
    final user = _currentUser;
    if (user == null || user.idToken == null) return;
    try {
      final response = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$_fbApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': user.idToken}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] as List;
        if (users.isNotEmpty) {
          final isVerified = users.first['emailVerified'] ?? false;
          _currentUser = _currentUser!.copyWith(isEmailVerified: isVerified);
          await _saveUserToPrefs(_currentUser!);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // --- Delete Account ---
  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null || user.idToken == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$_fbApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': user.idToken}),
      );
      if (response.statusCode == 200) {
        await signOut();
      } else {
        final data = json.decode(response.body);
        _errorMessage = _parseFirebaseAuthError(data['error']['message']);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 8. Sign Out ---
`;

code = code.replace(/\/\/ --- [0-9]+\. Sign Out ---/, newMethods);
fs.writeFileSync('lib/services/auth_service.dart', code);
console.log('Added reload and delete to auth_service');
