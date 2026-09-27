const fs = require('fs');
let code = fs.readFileSync('lib/screens/bookmarks_view.dart', 'utf8');

code = code.replace(/return ExecutiveCardView\(\s*article: article,\s*allArticles: provider\.bookmarks,\s*itemIndex: index,\s*\);/g, "return ExecutiveCardView(article: article);");

fs.writeFileSync('lib/screens/bookmarks_view.dart', code);
console.log('done bookmarks view');
