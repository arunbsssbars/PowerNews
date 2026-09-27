const fs = require('fs');
let code = fs.readFileSync('lib/widgets/executive_card_view.dart', 'utf8');

if (!code.includes('cached_network_image.dart')) {
  code = code.replace(/import 'package:flutter\/material.dart';/, "import 'package:flutter/material.dart';\nimport 'package:cached_network_image/cached_network_image.dart';");
}

code = code.replace(/Image\.network\([\s\S]*?_buildFallbackBanner\(isDark, catColor\),\n\s*\)/, CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              memCacheWidth: 600,
              memCacheHeight: 400,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              errorWidget: (context, url, error) => _buildFallbackBanner(isDark, catColor),
            ));

fs.writeFileSync('lib/widgets/executive_card_view.dart', code);
console.log('done');
