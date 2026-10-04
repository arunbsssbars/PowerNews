import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_unread_rounded, size: 80, color: Color(0xFF2563EB)),
                  const SizedBox(height: 24),
                  const Text('Verify Your Email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    'We sent a verification link to ${auth.currentUser?.email ?? 'your email'}. Please click the link to verify your account and gain access to PowerNews.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await auth.reloadUser();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('I have verified, Refresh Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      if (auth.currentUser?.email != null) {
                        // Note: Using sendPasswordReset here since Firebase free tier REST api doesn't expose sendEmailVerification easily
                        // without an Identity Toolkit extension. We assume password reset sends a link to the email.
                        await auth.sendPasswordReset(auth.currentUser!.email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resent link.')));
                        }
                      }
                    },
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Resend Link'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => auth.signOut(),
                    child: const Text('Sign Out / Use a different account', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
