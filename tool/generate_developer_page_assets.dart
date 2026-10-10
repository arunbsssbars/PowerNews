import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Generating Google Play Developer Page assets...');

  final outDir = Directory('builds/playstore');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final sourceFile = File('assets/icons/app_icon.png');
  if (!sourceFile.existsSync()) {
    throw Exception('Source file assets/icons/app_icon.png not found!');
  }

  final sourceBytes = sourceFile.readAsBytesSync();
  final sourceImg = img.decodePng(sourceBytes)!;
  print('Loaded source icon: ${sourceImg.width}x${sourceImg.height}');

  // 1. Developer icon (512x512, non-transparent 24-bit PNG/JPEG)
  // Ensure solid non-transparent background
  final devIcon = img.Image(width: 512, height: 512, numChannels: 3); // 3 channels = RGB (no alpha)
  // Fill solid white background
  img.fill(devIcon, color: img.ColorRgb8(255, 255, 255));
  
  // Resize source icon to 512x512
  final resizedSource = img.copyResize(sourceImg, width: 512, height: 512, interpolation: img.Interpolation.linear);
  img.compositeImage(devIcon, resizedSource);

  final devIconFile = File('builds/playstore/developer_icon_512.png');
  devIconFile.writeAsBytesSync(img.encodePng(devIcon));
  print('Generated ${devIconFile.path} (${devIconFile.lengthSync() / 1024} KB)');

  // 2. Header image (4096x2304, non-transparent, < 1 MB)
  // Aspect ratio is exactly 16:9 (4096 / 2304 = 1.7777...)
  final headerImg = img.Image(width: 4096, height: 2304, numChannels: 3); // RGB (no alpha)

  // Create an executive dark navy background gradient (#0B1528 -> #1E293B)
  // Start color: R: 11, G: 21, B: 40
  // End color:   R: 30, G: 41, B: 59
  for (int y = 0; y < 2304; y++) {
    final t = y / 2304.0;
    final r = (11 + (30 - 11) * t).round();
    final g = (21 + (41 - 21) * t).round();
    final b = (40 + (59 - 40) * t).round();
    final rowColor = img.ColorRgb8(r, g, b);
    for (int x = 0; x < 4096; x++) {
      headerImg.setPixel(x, y, rowColor);
    }
  }

  // Overlay a centered high-res brand emblem badge (e.g. 1000x1000)
  final badgeSize = 1000;
  final resizedBadge = img.copyResize(sourceImg, width: badgeSize, height: badgeSize, interpolation: img.Interpolation.linear);
  final badgeX = (4096 - badgeSize) ~/ 2;
  final badgeY = (2304 - badgeSize) ~/ 2;
  img.compositeImage(headerImg, resizedBadge, dstX: badgeX, dstY: badgeY);

  // Encode as JPEG with quality 85 to ensure file size is comfortably under 1 MB limit (e.g. 400-600 KB)
  final headerJpgBytes = img.encodeJpg(headerImg, quality: 85);
  final headerFile = File('builds/playstore/developer_header_4096x2304.jpg');
  headerFile.writeAsBytesSync(headerJpgBytes);
  print('Generated ${headerFile.path} (${headerFile.lengthSync() / 1024} KB, must be < 1024 KB)');

  print('Done generating developer page assets!');
}
