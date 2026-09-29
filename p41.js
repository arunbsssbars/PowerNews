const fs = require('fs');
let code = fs.readFileSync('lib/widgets/formatted_summary_view.dart', 'utf8');

// For bullets:
const tBullet = `textAlign: TextAlign.justify,
                        ),
                      ),`;
const rBullet = `textAlign: TextAlign.justify,
                          maxLines: isScrollable ? null : Math.max(1, (constraints.maxHeight / (effectiveFontSize * lineHeight * 1.2)).floor()),
                          overflow: isScrollable ? null : TextOverflow.ellipsis,
                        ),
                      ),`;
code = code.replace(tBullet, rBullet.replace(/Math\.max/, 'math.max')); // Need to import math

// For prose:
const tProse = `textAlign: TextAlign.justify,
            ),
          );`;
const rProse = `textAlign: TextAlign.justify,
              maxLines: isScrollable ? null : math.max(1, (constraints.maxHeight / (effectiveFontSize * lineHeight)).floor()),
              overflow: isScrollable ? null : TextOverflow.ellipsis,
            ),
          );`;
code = code.replace(tProse, rProse);

const importMath = `import 'dart:math' as math;
import 'package:flutter/material.dart';`;
code = code.replace(/import 'package:flutter\/material.dart';/, importMath);

fs.writeFileSync('lib/widgets/formatted_summary_view.dart', code);
console.log('Added maxLines and ellipsis');
