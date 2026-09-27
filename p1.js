const fs = require("fs");
let code = fs.readFileSync("lib/widgets/executive_card_view.dart", "utf8");

if (!code.includes("cached_network_image.dart")) {
  code = code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:cached_network_image/cached_network_image.dart';");
}

const oldImage = `            Image.network(
              imgUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(isDark, catColor),
            ),`;

const newImage = `            CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              memCacheWidth: 600,
              memCacheHeight: 400,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              errorWidget: (context, url, error) => _buildFallbackBanner(isDark, catColor),
            ),`;

code = code.replace(oldImage, newImage);
fs.writeFileSync("lib/widgets/executive_card_view.dart", code);
console.log("executive_card_view done");
