const fs = require('fs');
let code = fs.readFileSync('lib/theme/app_theme.dart', 'utf8');

code = code.replace(/static const Color darkBg = Color\(0xFF0D1117\);.*\n/g, 'static const Color darkBg = Color(0xFF121212);\n');
code = code.replace(/static const Color darkSurface = Color\(0xFF111827\);.*\n/g, 'static const Color darkSurface = Color(0xFF1E1E1E);\n');
code = code.replace(/static const Color darkSurfaceElevated = Color\(0xFF1F2937\);.*\n/g, 'static const Color darkSurfaceElevated = Color(0xFF2C2C2C);\n');
code = code.replace(/static const Color darkBorder = Color\(0xFF263040\);.*\n/g, 'static const Color darkBorder = Color(0xFF333333);\n');
code = code.replace(/static const Color darkTextPrimary = Color\(0xFFF8FAFC\);.*\n/g, 'static const Color darkTextPrimary = Color(0xFFE0E0E0);\n');
code = code.replace(/static const Color darkTextSecondary = Color\(0xFF94A3B8\);.*\n/g, 'static const Color darkTextSecondary = Color(0xFF9E9E9E);\n');
code = code.replace(/static const Color darkTextMuted = Color\(0xFF64748B\);.*\n/g, 'static const Color darkTextMuted = Color(0xFF757575);\n');
code = code.replace(/static const Color darkPrimary = Color\(0xFF38BDF8\);.*\n/g, 'static const Color darkPrimary = Color(0xFF29B6F6);\n');
code = code.replace(/static const Color darkAccent = Color\(0xFFFBBF24\);.*\n/g, 'static const Color darkAccent = Color(0xFFFFCA28);\n');
code = code.replace(/backgroundColor: const Color\(0xFF10151E\),/g, 'backgroundColor: const Color(0xFF121212),');

fs.writeFileSync('lib/theme/app_theme.dart', code);
console.log('done theme');
