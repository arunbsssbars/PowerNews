const fs = require('fs');
let code = fs.readFileSync('lib/screens/home_screen.dart', 'utf8');

// Remove animation controller setup
code = code.replace(/late AnimationController _refreshAnimController;\n/g, "");
code = code.replace(/_refreshAnimController = AnimationController\([\s\S]*?vsync: this,\n\s*duration: const Duration\(milliseconds: 900\),\n\s*\);\n/g, "");
code = code.replace(/\s*_refreshAnimController\.dispose\(\);\n/g, "");

// Remove the refresh button block EXACTLY
const refreshBtnBlock = // 2. Refresh Button (Comfortable 36x36 touch target)
          Tooltip(
            message: 'Refresh Feeds',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                _refreshAnimController.repeat();
                try {
                  await provider.triggerFullRefresh();
                } finally {
                  if (mounted) {
                    _refreshAnimController.animateTo(1.0, curve: Curves.easeOut).then((_) {
                      if (mounted) _refreshAnimController.reset();
                    });
                  }
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.7) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: RotationTransition(
                    turns: _refreshAnimController,
                    child: Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),;

if (code.includes("Tooltip(\n            message: 'Refresh Feeds',")) {
   code = code.replace(refreshBtnBlock, "");
} else {
   console.log("Could not find exact block!");
}

fs.writeFileSync('lib/screens/home_screen.dart', code);
console.log('done home_screen carefully');
