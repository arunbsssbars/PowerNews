import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Processing Android launcher icon for Web...');

  // Try mipmap-xxxhdpi/launcher_icon.png first, fallback to app_icon.png
  final file = File('android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png');
  final bytes = file.readAsBytesSync();
  var rawImg = img.decodePng(bytes)!;

  print('Source size: ${rawImg.width}x${rawImg.height}');
  print('Pixel (0,0): R=${rawImg.getPixel(0, 0).r}, G=${rawImg.getPixel(0, 0).g}, B=${rawImg.getPixel(0, 0).b}, A=${rawImg.getPixel(0, 0).a}');

  // If pixel (0,0) is white or opaque non-background, convert white background to transparent
  final transparentLogo = img.Image(width: rawImg.width, height: rawImg.height, numChannels: 4);
  for (int y = 0; y < rawImg.height; y++) {
    for (int x = 0; x < rawImg.width; x++) {
      final p = rawImg.getPixel(x, y);
      // If near white, make transparent
      if (p.r > 245 && p.g > 245 && p.b > 245) {
        transparentLogo.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        transparentLogo.setPixel(x, y, p);
      }
    }
  }

  // Brand background color #0B1528 -> R: 11, G: 21, B: 40
  final bgColor = img.ColorRgb8(11, 21, 40);

  // 1. Generate 512x512 full Android launcher icon with brand dark background
  final androidWeb512 = img.Image(width: 512, height: 512);
  img.fill(androidWeb512, color: bgColor);

  // Inset logo comfortably (~72% of canvas)
  final logoSize512 = (512 * 0.72).round();
  final resizedLogo512 = img.copyResize(transparentLogo, width: logoSize512, height: logoSize512, interpolation: img.Interpolation.linear);
  final offset512 = (512 - logoSize512) ~/ 2;
  img.compositeImage(androidWeb512, resizedLogo512, dstX: offset512, dstY: offset512);

  // 2. Generate 192x192
  final androidWeb192 = img.copyResize(androidWeb512, width: 192, height: 192, interpolation: img.Interpolation.linear);

  // 3. Generate crisp Favicon: A transparent background with crisp logo, and a 64x64/32x32 variant
  // Usually in browser tabs, transparent background or themed badge looks amazing. Let's make favicon crisp with transparent or rounded brand badge
  // A rounded square brand badge favicon stands out brilliantly on both dark and light browser tabs!
  final favicon = img.copyResize(androidWeb512, width: 64, height: 64, interpolation: img.Interpolation.linear);

  // Save to web/
  File('web/icons/Icon-512.png').writeAsBytesSync(img.encodePng(androidWeb512));
  File('web/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(androidWeb512));
  File('web/icons/Icon-192.png').writeAsBytesSync(img.encodePng(androidWeb192));
  File('web/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(androidWeb192));
  File('web/favicon.png').writeAsBytesSync(img.encodePng(favicon));

  // Save to public/web/
  File('public/web/icons/Icon-512.png').writeAsBytesSync(img.encodePng(androidWeb512));
  File('public/web/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(androidWeb512));
  File('public/web/icons/Icon-192.png').writeAsBytesSync(img.encodePng(androidWeb192));
  File('public/web/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(androidWeb192));
  File('public/web/favicon.png').writeAsBytesSync(img.encodePng(favicon));

  print('Successfully created clean, seamless Android launcher icons for Web!');
}
