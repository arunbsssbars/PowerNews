const fs = require('fs');
let code = fs.readFileSync('lib/screens/bookmarks_view.dart', 'utf8');

code = code.replace(/return ExecutiveCardView\(article: article\);/g, "return ExecutiveCardView(article: article, currentIndex: index, totalCount: provider.bookmarks.length);");

fs.writeFileSync('lib/screens/bookmarks_view.dart', code);
console.log('done bookmarks view update');
