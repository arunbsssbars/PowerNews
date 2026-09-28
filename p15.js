const fs = require('fs');
let code = fs.readFileSync('lib/screens/feed_view.dart', 'utf8');

// Replace physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
// with physics: const PageScrollPhysics(),
code = code.replace(/physics:\s*const\s*BouncingScrollPhysics\(parent:\s*AlwaysScrollableScrollPhysics\(\)\),/g, 'physics: const PageScrollPhysics(),');

fs.writeFileSync('lib/screens/feed_view.dart', code);
console.log('fixed physics');
