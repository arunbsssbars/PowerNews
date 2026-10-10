import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../main.dart';
import '../providers/news_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/about_sheet.dart';
import 'admin_dashboard_screen.dart';
import 'onboarding_screen.dart';

/// Production Executive Profile View.
/// Complies with AQIL standards:
/// - Responsive constraint clamped to maxWidth 620 for tablet/desktop
/// - Safe touch targets (>= 44x44 dp)
/// - Clean role boundary: strips backend/crawler clutter for regular readers
/// - Root Admin command center preserved exclusively for [arunbsssbars@gmail.com]
/// - Google Play compliance: Account deletion & Privacy policy link
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchPrivacyPolicy() async {
    const url = 'https://powernews-app-2026.web.app/privacy.html';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showEditProfileDialog(BuildContext context, AuthService auth) {
    final user = auth.currentUser;
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.displayName);
    final photoCtrl = TextEditingController(text: user.photoUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.badge_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text(
                'Edit Profile Details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name / Title',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                decoration: InputDecoration(
                  labelText: 'Profile Photo URL (optional)',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newPhoto = photoCtrl.text.trim().isEmpty ? null : photoCtrl.text.trim();
                if (newName.isNotEmpty) {
                  await auth.updateProfileDetails(displayName: newName, photoUrl: newPhoto);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile details updated successfully!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to sign out of your PowerNews account session?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'This will permanently delete your account, saved preferences, and stored bookmarks from PowerNews. This action cannot be reversed.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.deleteAccount();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.feedback_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text('Submit Feedback', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Help us improve PowerNews. Send us feature requests, energy utility updates, or general feedback.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your suggestion or report...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  try {
                    await http.post(
                      Uri.parse('${AppConfig.apiBaseUrl}/feedbacks'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'email': user.email,
                        'message': ctrl.text.trim(),
                        'type': 'suggestion',
                      }),
                    );
                  } catch (_) {}
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you! Your feedback has been transmitted to our editorial team.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final newsProvider = context.watch<NewsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;

    final bgCard = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // 1. Sleek, Executive App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF0D1322) : Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  user != null ? (isAdmin ? 'Admin Console' : 'Profile & Settings') : 'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (user != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit Profile Details',
                      onPressed: () => _showEditProfileDialog(context, auth),
                    ),
                  if (user != null)
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      tooltip: 'Sign Out',
                      onPressed: () => _confirmSignOut(context, auth),
                    ),
                  const SizedBox(width: 8),
                ],
              ),

              // 2. Profile Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- A. Identity Card ---
                      _buildIdentityCard(
                        context,
                        user,
                        isAdmin,
                        auth,
                        isDark,
                        bgCard,
                        borderColor,
                        textPrimary,
                        textSecondary,
                      ),

                      // --- B. Admin Quick Command Center (Exclusively for Root Admin) ---
                      if (isAdmin) ...[
                        const SizedBox(height: 20),
                        _buildAdminCommandGrid(
                          context,
                          isDark,
                          bgCard,
                          borderColor,
                          textPrimary,
                          textSecondary,
                        ),
                      ],

                      // --- C. Personal Reading Activity (Cleaned of crawler metrics) ---
                      const SizedBox(height: 20),
                      _buildReadingActivityCard(
                        context,
                        newsProvider,
                        isDark,
                        bgCard,
                        borderColor,
                        textPrimary,
                        textSecondary,
                      ),

                      // --- D. Preferences & Content Controls ---
                      const SizedBox(height: 20),
                      _buildPreferencesCard(
                        context,
                        newsProvider,
                        isDark,
                        bgCard,
                        borderColor,
                        textPrimary,
                        textSecondary,
                      ),

                      // --- E. Legal & Editorial Support Card ---
                      const SizedBox(height: 20),
                      _buildLegalAndSupportCard(
                        context,
                        user,
                        isDark,
                        bgCard,
                        borderColor,
                        textPrimary,
                        textSecondary,
                      ),

                      // --- F. Account Actions & Session Control ---
                      if (user != null) ...[
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => _confirmSignOut(context, auth),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign Out of Session', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (!isAdmin) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => _confirmDeleteAccount(context, auth),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF94A3B8),
                              minimumSize: const Size.fromHeight(44),
                            ),
                            icon: const Icon(Icons.delete_forever_outlined, size: 17),
                            label: const Text('Delete Account & Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ],

                      // App Version Footer
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'PowerNews v1.0.0 • Build 1 • Enterprise Energy Intelligence',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // IDENTITY HERO CARD
  // ===========================================================================
  Widget _buildIdentityCard(
    BuildContext context,
    AppUser? user,
    bool isAdmin,
    AuthService auth,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with live indicator ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                        width: 2.4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Builder(builder: (context) {
                        final String? userPhoto = user.photoUrl;
                        if (userPhoto != null && userPhoto.isNotEmpty) {
                          return Image.network(
                            userPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitialsAvatar(user.displayName),
                          );
                        }
                        return _buildInitialsAvatar(user.displayName);
                      }),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: bgCard, width: 2),
                    ),
                    child: Icon(
                      isAdmin ? Icons.star_rounded : Icons.check_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Role & Verification Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                : const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isAdmin ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFF2563EB).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isAdmin ? 'ROOT ADMIN' : 'EXECUTIVE READER',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: user.isEmailVerified
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: user.isEmailVerified
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isEmailVerified ? Icons.verified_rounded : Icons.pending_rounded,
                                size: 10,
                                color: user.isEmailVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                user.isEmailVerified ? 'VERIFIED' : 'UNVERIFIED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: user.isEmailVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),

          // Clean Meta Strip
          Row(
            children: [
              Expanded(
                child: _buildMetaPill(
                  label: 'PROVIDER',
                  value: user.authProvider == 'google' ? 'Google Account' : 'Direct Email',
                  color: const Color(0xFF2563EB),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetaPill(
                  label: 'STATUS',
                  value: 'Active Session',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADMIN COMMAND GRID (Exclusive for Root Admin)
  // ===========================================================================
  Widget _buildAdminCommandGrid(
    BuildContext context,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Admin Command Center',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen(initialTabIndex: 0)),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'Full Console',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF10B981)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2x2 Grid of Actions
        Row(
          children: [
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'Live Feed',
                subtitle: 'Filter & verify ingestion',
                icon: Icons.dynamic_feed_rounded,
                accentColor: const Color(0xFF0284C7),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'Keywords',
                subtitle: 'Taxonomy & discovery',
                icon: Icons.tag_rounded,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'ML Curation',
                subtitle: 'Dataset scoring metrics',
                icon: Icons.psychology_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 2,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'Telemetry',
                subtitle: 'Cloud sync & health',
                icon: Icons.health_and_safety_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color bgCard,
    required Color borderColor,
    required int tabIndex,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(initialTabIndex: tabIndex),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // READING ACTIVITY CARD (Clean Reader Metrics Only)
  // ===========================================================================
  Widget _buildReadingActivityCard(
    BuildContext context,
    NewsProvider newsProvider,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 17, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reading Intelligence & Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Articles Read',
                  value: '${newsProvider.totalReadCount}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.bookmark_added_rounded,
                  color: const Color(0xFFF59E0B),
                  label: 'Saved Bookmarks',
                  value: '${newsProvider.bookmarks.length}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PREFERENCES & APP EXPERIENCE
  // ===========================================================================
  Widget _buildPreferencesCard(
    BuildContext context,
    NewsProvider newsProvider,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Material(
      color: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFF2563EB)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                size: 20,
              ),
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'High-contrast executive theme',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            value: isDark,
            activeThumbColor: const Color(0xFF2563EB),
            onChanged: (_) => newsProvider.toggleTheme(),
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.explore_rounded, color: Color(0xFF0284C7), size: 20),
            ),
            title: Text(
              'Tour & Gesture Guide',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'Review swipe gestures, sectors & utility shortcuts',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 20),
            ),
            title: Text(
              'Editorial Standards & Attribution',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              '60-word summarization ethics & source integrity',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => AboutSheet.show(context),
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.offline_pin_rounded, color: Color(0xFF6366F1), size: 20),
            ),
            title: Text(
              'Offline Reading Cache',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Consumer<NewsProvider>(
              builder: (context, news, _) {
                final count = news.articles.length;
                return Text(
                  '$count offline articles cached locally',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                );
              },
            ),
            trailing: TextButton(
              onPressed: () async {
                final scaffold = ScaffoldMessenger.of(context);
                try {
                  await DatabaseService().clearUnbookmarkedCache();
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('Offline cache cleared (bookmarked articles preserved).'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() {});
                } catch (e) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Optimize', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LEGAL & SUPPORT CARD (Play Store Compliance)
  // ===========================================================================
  Widget _buildLegalAndSupportCard(
    BuildContext context,
    AppUser? user,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Material(
      color: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF3B82F6), size: 20),
            ),
            title: Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'Review data handling, security & disclosures',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: _launchPrivacyPolicy,
          ),
          if (user != null) ...[
            Divider(height: 1, color: borderColor),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              title: Text(
                'Submit Feedback / Bug Report',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              subtitle: Text(
                'Send thoughts directly to the developer team',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => _showFeedbackDialog(context, user),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      color: const Color(0xFF2563EB),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
