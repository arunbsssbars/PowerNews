const fs = require('fs');
let code = fs.readFileSync('lib/screens/admin_dashboard_screen.dart', 'utf8');

// Fix TabBar to include the 6th tab
const oldTabs = `            tabs: const [
              Tab(text: 'Live Feed', icon: Icon(Icons.newspaper_rounded, size: 16)),
              Tab(text: 'Keywords', icon: Icon(Icons.auto_awesome_rounded, size: 16)),
              Tab(text: 'ML Data', icon: Icon(Icons.model_training_rounded, size: 16)),
              Tab(text: 'Health', icon: Icon(Icons.monitor_heart_rounded, size: 16)),
              Tab(text: 'Data Playbook', icon: Icon(Icons.menu_book_rounded, size: 16)),
            ],`;

const newTabs = `            tabs: const [
              Tab(text: 'Live Feed', icon: Icon(Icons.newspaper_rounded, size: 16)),
              Tab(text: 'Keywords', icon: Icon(Icons.auto_awesome_rounded, size: 16)),
              Tab(text: 'ML Data', icon: Icon(Icons.model_training_rounded, size: 16)),
              Tab(text: 'Health', icon: Icon(Icons.monitor_heart_rounded, size: 16)),
              Tab(text: 'Data Playbook', icon: Icon(Icons.menu_book_rounded, size: 16)),
              Tab(text: 'User Feedbacks', icon: Icon(Icons.feedback_rounded, size: 16)),
            ],`;
code = code.replace(oldTabs, newTabs);

// Fix the telemetry data keys
code = code.replace(/final heapUsed = _memoryData\?\['heapUsed'\] \?\? 'N\/A';/, `final heapUsed = _memoryData?['heapUsedMb'] ?? 'N/A';`);
code = code.replace(/final rss = _memoryData\?\['rss'\] \?\? 'N\/A';/, `final rss = _memoryData?['rssMb'] ?? 'N/A';`);

fs.writeFileSync('lib/screens/admin_dashboard_screen.dart', code);
console.log('Fixed admin dashboard');
