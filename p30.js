const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

// length 5 -> 6
code = code.replace(/length: 5/, 'length: 6');

// Tab bar items
const newTab = `
              const Tab(icon: Icon(Icons.settings_suggest_rounded), text: 'API Playbook'),
              const Tab(icon: Icon(Icons.feedback_rounded), text: 'User Feedbacks'),
`;
code = code.replace(/const Tab\(icon: Icon\(Icons\.settings_suggest_rounded\), text: 'API Playbook'\),/, newTab);

// TabBarView children
const tabViewChildren = `
          _buildDataPlaybookTab(isDark),
          _buildFeedbackTab(isDark),
`;
code = code.replace(/_buildDataPlaybookTab\(isDark\),/, tabViewChildren);

// Fetch Feedbacks State
const fetchState = `
  List<dynamic> _feedbacks = [];
  bool _isLoadingFeedbacks = false;

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoadingFeedbacks = true);
    try {
      final res = await http.get(Uri.parse('\${AppConfig.apiBaseUrl}/feedbacks'));
      if (res.statusCode == 200) {
        setState(() => _feedbacks = json.decode(res.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFeedbacks = false);
  }
`;
code = code.replace(/  \/\/ Tab 2: Keywords State/, fetchState + '\n  // Tab 2: Keywords State');
code = code.replace(/_fetchHealth\(\);/, '_fetchHealth();\n    _fetchFeedbacks();');

// Feedback Tab Widget
const feedbackWidget = `
  Widget _buildFeedbackTab(bool isDark) {
    if (_isLoadingFeedbacks) return const Center(child: CircularProgressIndicator());
    if (_feedbacks.isEmpty) return const Center(child: Text('No feedbacks yet.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _feedbacks.length,
      itemBuilder: (ctx, i) {
        final f = _feedbacks[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(f['type'] == 'bug' ? Icons.bug_report : Icons.lightbulb, color: Colors.blue),
            title: Text(f['message'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('From: \${f['email'] ?? 'Anonymous'}\\n\${f['timestamp'] ?? ''}'),
            isThreeLine: true,
          ),
        );
      }
    );
  }
`;
code = code.replace(/class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin \{/, 
  'class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {\n' + feedbackWidget);

fs.writeFileSync('lib/screens/admin_dashboard_screen.dart', code);
console.log('Admin Dashboard Patched');
