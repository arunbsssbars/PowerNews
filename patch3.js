const fs = require('fs');
let code = fs.readFileSync('lib/screens/bookmarks_view.dart', 'utf8');
code = code.replace(/import '\.\.\/widgets\/news_card\.dart';/, "import '../widgets/executive_card_view.dart';");
code = code.replace(/return NewsCard\(/g, "return ExecutiveCardView(");
fs.writeFileSync('lib/screens/bookmarks_view.dart', code);
console.log('done bookmarks');
