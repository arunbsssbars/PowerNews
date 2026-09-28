const fs = require('fs');
let code = fs.readFileSync('lib/screens/profile_view.dart', 'utf8');

const replacement = `
                  // --- E. Sign Out Action Button (if signed in) ---
                  if (user != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open Feedback modal
                        _showFeedbackDialog(context, user);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.feedback_rounded, size: 18),
                      label: const Text('Submit Feedback / Suggestion', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, auth),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out of Session', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteAccount(context, auth),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Delete Account Data', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
`;
code = code.replace(/                  \/\/ --- E\. Sign Out Action Button \(if signed in\) ---[\s\S]*?\]\,/, replacement);

// Add Feedback Dialog and Delete Account Confirm functions below _confirmSignOut
const funcs = `
  void _confirmDeleteAccount(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: const Text('This will permanently purge all your data and session. You cannot undo this action.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.deleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context, AppUser user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Submit Feedback'),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your ideas or issues...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.isNotEmpty) {
                  try {
                    await http.post(
                      Uri.parse('\${AppConfig.apiBaseUrl}/feedbacks'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'email': user.email, 'message': ctrl.text, 'type': 'suggestion'}),
                    );
                  } catch (_) {}
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
`;
code = code.replace(/Widget build\(BuildContext context\) \{/, funcs + '\n\n  @override\n  Widget build(BuildContext context) {');

// We also need to import http and dart:convert at the top if they are missing
code = "import 'dart:convert';\nimport 'package:http/http.dart' as http;\nimport '../config/app_config.dart';\n" + code;

fs.writeFileSync('lib/screens/profile_view.dart', code);
console.log('Profile view patched');
