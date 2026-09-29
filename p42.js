const fs = require('fs');
let code = fs.readFileSync('lib/widgets/formatted_summary_view.dart', 'utf8');

if (!code.includes("import 'dart:math' as math;")) {
  code = code.replace("import 'package:flutter/material.dart';", "import 'dart:math' as math;\nimport 'package:flutter/material.dart';");
}

code = code.replace(/textAlign: TextAlign.justify,\s*\),/g, `textAlign: TextAlign.justify,\n                          maxLines: isScrollable ? null : math.max(1, (constraints.maxHeight / (effectiveFontSize * lineHeight)).floor()),\n                          overflow: isScrollable ? null : TextOverflow.ellipsis,\n                        ),`);

fs.writeFileSync('lib/widgets/formatted_summary_view.dart', code);
console.log('Fixed maxLines');
