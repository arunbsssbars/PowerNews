const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

// 1. TabController length 3 -> 4
code = code.replace(/length: 3/, 'length: 4');

// 2. Add Tab icon in TabBar
const newTab = `
                const Tab(icon: Icon(Icons.psychology_alt_rounded), text: 'AI Training'),
                const Tab(icon: Icon(Icons.feedback_rounded), text: 'User Feedback'),
`;
code = code.replace(/const Tab\(icon: Icon\(Icons\.psychology_alt_rounded\), text: 'AI Training'\),/, newTab);

// 3. State variables for Feedback
const stateVars = `
  // Tab 4: Feedback State
  List<dynamic> _feedbacks = [];
  bool _isLoadingFeedbacks = false;

`;
code = code.replace(/  \/\/ Tab 3: ML Training State/, stateVars + '  // Tab 3: ML Training State');

// 4. Fetch Feedback method
const fetchFeedbacks = `
  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoadingFeedbacks = true);
    try {
      final response = await http.get(Uri.parse('\${AppConfig.apiBaseUrl}/feedbacks'));
      if (response.statusCode == 200) {
        setState(() {
          _feedbacks = json.decode(response.body);
        });
      }
    } catch (_) {}
    setState(() => _isLoadingFeedbacks = false);
  }
`;
code = code.replace(/void initState\(\) \{/, fetchFeedbacks + '\n  @override\n  void initState() {');

// 5. Call fetchFeedbacks on init
code = code.replace(/_fetchModelStatus\(\);/, '_fetchModelStatus();\n    _fetchFeedbacks();');

// 6. Add TabView content
const feedbackTabView = `
            // TAB 4: User Feedback
            _buildFeedbackTab(),
          ],
`;
code = code.replace(/\]\,\s*\)\,\s*\)\,\s*\]\,\s*\)\,\s*\)\;/g, feedbackTabView + '        ),\n      ),\n    ],\n  ),\n);');

// Wait, the regex for replacing the end of TabBarView is tricky. Let's do it safely.
