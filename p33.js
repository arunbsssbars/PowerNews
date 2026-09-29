const fs = require('fs');
let code = fs.readFileSync('lib/screens/profile_view.dart', 'utf8');

const target = `                  // --- E. Sign Out Action Button (if signed in) ---
                  if (user != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(`;

const replacement = `                  // --- E. Sign Out Action Button (if signed in) ---
                  if (user != null) ...[
                    const SizedBox(height: 12),
                    if (!isAdmin)
                      ElevatedButton.icon(`;
code = code.replace(target, replacement);

const target2 = `                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteAccount(context, auth),`;

const replacement2 = `                    const SizedBox(height: 12),
                    if (!isAdmin)
                      TextButton.icon(
                        onPressed: () => _confirmDeleteAccount(context, auth),`;

code = code.replace(target2, replacement2);

fs.writeFileSync('lib/screens/profile_view.dart', code);
console.log('Fixed profile_view admin buttons');
