import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const String _webPrivacyUrl = 'https://powernews-app-2026.web.app/privacy.html';
  bool _useWebView = false;
  WebViewController? _webViewController;
  bool _isLoadingWeb = true;
  int _webProgress = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    }
  }

  void _initWebView() {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (mounted) setState(() => _webProgress = progress);
            },
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoadingWeb = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoadingWeb = false);
            },
            onWebResourceError: (error) {
              if (mounted) setState(() => _isLoadingWeb = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(_webPrivacyUrl));
    } catch (e) {
      debugPrint('[PrivacyPolicyScreen] WebViewController init error: $e');
    }
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(_webPrivacyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFF38BDF8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!kIsWeb && _webViewController != null)
            IconButton(
              icon: Icon(
                _useWebView ? Icons.article_outlined : Icons.language_rounded,
                color: accentColor,
              ),
              tooltip: _useWebView ? 'Switch to Native View' : 'Switch to Official Web View',
              onPressed: () {
                setState(() => _useWebView = !_useWebView);
              },
            ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open in Browser',
            onPressed: _launchExternal,
          ),
        ],
      ),
      body: _useWebView && !kIsWeb && _webViewController != null
          ? Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                if (_isLoadingWeb)
                  LinearProgressIndicator(
                    value: _webProgress / 100.0,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
                  ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'PowerNews Privacy Commitment',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last Updated: October 2026 • Effective Worldwide\nIndian Power Sector Intelligence Platform',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section 1: Overview
                  _buildSectionCard(
                    title: '1. Overview & Data Philosophy',
                    icon: Icons.shield_outlined,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    secondaryText: secondaryText,
                    content:
                        'PowerNews ("we", "our", or "the app") provides high-voltage power transmission, tariff regulations, and renewable energy market intelligence. We are committed to transparency and the highest standards of data privacy. We operate on a strict Data-Minimization and Offline-First principle.',
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Data Collection
                  _buildSectionCard(
                    title: '2. Information We Collect & Use',
                    icon: Icons.storage_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    secondaryText: secondaryText,
                    content:
                        '• Offline Storage: News articles, search histories, and custom bookmarks are stored locally on your device in a private SQLite database (powernews_offline.db).\n'
                        '• Optional Account Sync: If you voluntarily sign in via Google Auth or Email, your user profile ID, email, and bookmarks are synchronized with Cloud Firestore.\n'
                        '• Location (Optional): Used strictly on-device to filter regional state DISCOM tariffs and local solar tenders. Your precise GPS coordinates are never uploaded to our servers or sold to data brokers.\n'
                        '• Telemetry: Non-identifying application performance and crash telemetry to ensure zero layout overflows and high uptime.',
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Google Cloud & Backend Infrastructure
                  _buildSectionCard(
                    title: '3. Backend & Cloud Infrastructure',
                    icon: Icons.cloud_done_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    secondaryText: secondaryText,
                    content:
                        '• Google Cloud Functions 2nd Gen & Firebase: Serverless backend API processing with enterprise-grade encryption in transit (HTTPS/TLS 1.3).\n'
                        '• Google Cloud Firestore: Secure Native database (asia-south1) protected by strict Principle of Least Privilege and IAM role boundaries.\n'
                        '• Google Gemini AI: Synthesizes 50-100 word executive power briefs strictly grounded in publisher reports without personal user data ingestion.',
                  ),
                  const SizedBox(height: 14),

                  // Section 4: Publisher Attribution & Copyright
                  _buildSectionCard(
                    title: '4. Google Play Compliance & Attribution',
                    icon: Icons.newspaper_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    secondaryText: secondaryText,
                    content:
                        'PowerNews honors all original journalistic work. Every synthesized executive brief links directly to the publisher\'s canonical URL. We do not circumvent paywalls or reproduce full copyrighted articles without authorization. Publishers may contact us anytime for feed management or opt-outs.',
                  ),
                  const SizedBox(height: 14),

                  // Section 5: User Rights & Deletion
                  _buildSectionCard(
                    title: '5. Your Rights & Data Deletion',
                    icon: Icons.delete_outline_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    secondaryText: secondaryText,
                    content:
                        'You may clear your local offline cache anytime from the Profile tab. If you created a synchronized account, you may request complete account and bookmark deletion by emailing support@powernews.app. Requests are processed within 48 hours.',
                  ),
                  const SizedBox(height: 14),

                  // Contact Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questions or Feedback?',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Email our privacy officer at support@powernews.app or view the official web version anytime.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.email_outlined, size: 16),
                              label: const Text('Email Support', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                final mailUri = Uri.parse('mailto:support@powernews.app?subject=PowerNews%20Privacy%20Inquiry');
                                if (await canLaunchUrl(mailUri)) {
                                  await launchUrl(mailUri);
                                }
                              },
                            ),
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                              label: const Text('Open Official Web URL', style: TextStyle(fontSize: 12)),
                              onPressed: _launchExternal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color secondaryText,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
