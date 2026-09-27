const fs = require('fs');
let code = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

code = code.replace(/late AnimationController _refreshAnimController;\r?\n/g, "");
code = code.replace(/_refreshAnimController = AnimationController\([\s\S]*?vsync: this,\r?\n\s*duration: const Duration\(milliseconds: 900\),\r?\n\s*\);\r?\n/g, "");
code = code.replace(/\s*_refreshAnimController\.dispose\(\);\r?\n/g, "");

const regex = /\/\/ 2\. Refresh Button \([\s\S]*?Tooltip\([\s\S]*?message: 'Refresh Feeds'[\s\S]*?child: RotationTransition\([\s\S]*?Icons\.sync_rounded,[\s\S]*?color: Theme\.of\(context\)\.colorScheme\.primary,\r?\n\s*\),\r?\n\s*\),\r?\n\s*\),\r?\n\s*\),\r?\n\s*\),\r?\n\s*\),/g;

code = code.replace(regex, "");

fs.writeFileSync('lib/screens/home_screen.dart', code);
console.log('done home_screen carefully with literal string');
