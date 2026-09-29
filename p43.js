const fs = require('fs');
let code = fs.readFileSync('lib/widgets/formatted_summary_view.dart', 'utf8');

if (!code.includes("import 'dart:math' as math;")) {
  code = code.replace("import 'package:flutter/material.dart';", "import 'dart:math' as math;\nimport 'package:flutter/material.dart';");
}

const tBullet = `textAlign: TextAlign.justify,
                      ),`;
const rBullet = `textAlign: TextAlign.justify,
                          maxLines: isScrollable ? null : math.max(1, (constraints.maxHeight / (effectiveFontSize * lineHeight * 1.5)).floor()),
                          overflow: isScrollable ? null : TextOverflow.ellipsis,
                      ),`;
code = code.replace(tBullet, rBullet);

const tProse = `textAlign: TextAlign.justify,
            ),`;
const rProse = `textAlign: TextAlign.justify,
              maxLines: isScrollable ? null : math.max(1, (constraints.maxHeight / (effectiveFontSize * lineHeight * 1.1)).floor()),
              overflow: isScrollable ? null : TextOverflow.ellipsis,
            ),`;
code = code.replace(tProse, rProse);

fs.writeFileSync('lib/widgets/formatted_summary_view.dart', code);
console.log('Fixed maxLines precisely');
