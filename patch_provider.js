const fs = require('fs');
let code = fs.readFileSync('lib/providers/news_provider.dart', 'utf8');
code = code.replace(/"\[NewsProvider\] Error fetching more news: " \+ e\.toString\(\)/, '"[NewsProvider] Error fetching more news: \"');
fs.writeFileSync('lib/providers/news_provider.dart', code);
