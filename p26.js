const fs = require('fs');
let code = fs.readFileSync('lib/screens/login_signup_screen.dart', 'utf8');

// Replace the SafeArea > child > Center > SingleChildScrollView structure
code = code.replace(/body: SafeArea\(\s*child: Center\(\s*child: SingleChildScrollView\(/, `body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(`);

// At the end of SingleChildScrollView, we need to add the closing tags for LayoutBuilder
code = code.replace(/child: Column\(/, `child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: Center(
                    child: Column(`);

// Add the extra closing brackets before the end of the build method
// Actually it's easier to just do string replacements on exact lines or write a simpler regex

// Or simpler: change scaffold
