const fs = require('fs');
let code = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

// Remove animation controller declarations and usage
code = code.replace(/late AnimationController _refreshAnimController;\n/g, "");
code = code.replace(/_refreshAnimController = AnimationController\([\s\S]*?\);\n/g, "");
code = code.replace(/_refreshAnimController\.dispose\(\);\n/g, "");

// Remove the tooltip block completely
code = code.replace(/\/\/ 2\. Refresh Button \([\s\S]*?Tooltip\([\s\S]*?message: 'Refresh Feeds'[\s\S]*?Icon\(\n\s*Icons\.sync_rounded,\n\s*size: 20,\n\s*color: Theme\.of\(context\)\.colorScheme\.primary,\n\s*\),\n\s*\),\n\s*\),\n\s*\),\n\s*\),\n/g, "");

fs.writeFileSync('lib/screens/home_screen.dart', code);
console.log('done home_screen');
