const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

const t = `            tabs: const [
              Tab(text: 'Live Feed', icon: Icon(Icons.newspaper_rounded, size: 16)),
              Tab(text: 'Keywords', icon: Icon(Icons.auto_awesome_rounded, size: 16)),
              Tab(text: 'ML Data', icon: Icon(Icons.model_training_rounded, size: 16)),
              Tab(text: 'Health', icon: Icon(Icons.monitor_heart_rounded, size: 16)),
              Tab(text: 'Data Playbook', icon: Icon(Icons.menu_book_rounded, size: 16)),
            ],`;
const r = `            tabs: const [
              Tab(text: 'Live Feed', icon: Icon(Icons.newspaper_rounded, size: 16)),
              Tab(text: 'Keywords', icon: Icon(Icons.auto_awesome_rounded, size: 16)),
              Tab(text: 'ML Data', icon: Icon(Icons.model_training_rounded, size: 16)),
              Tab(text: 'Health', icon: Icon(Icons.monitor_heart_rounded, size: 16)),
              Tab(text: 'Data Playbook', icon: Icon(Icons.menu_book_rounded, size: 16)),
              Tab(text: 'User Feedbacks', icon: Icon(Icons.feedback_rounded, size: 16)),
            ],`;
code = code.replace(t, r);
fs.writeFileSync('lib/screens/admin_dashboard_screen.dart', code);
console.log('Fixed tabs');
