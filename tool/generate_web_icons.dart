import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Generating Web & PWA icons using front-end app icon (light background)...');

  // Load the front-end app icon (1024x1024 with light background)
  final sourceFile = File('assets/icons/app_icon.png');
  if (!sourceFile.existsSync()) {
    throw Exception('Source file assets/icons/app_icon.png not found!');
  }
  final bytes = sourceFile.readAsBytesSync();
  final sourceImg = img.decodePng(bytes)!;
  print('Loaded source app icon: ${sourceImg.width}x${sourceImg.height}');

  // 1. Generate 512x512
  final icon512 = img.copyResize(sourceImg, width: 512, height: 512, interpolation: img.Interpolation.linear);

  // 2. Generate 192x192
  final icon192 = img.copyResize(sourceImg, width: 192, height: 192, interpolation: img.Interpolation.linear);

  // 3. Generate crisp 64x64 favicon
  final favicon = img.copyResize(sourceImg, width: 64, height: 64, interpolation: img.Interpolation.linear);

  // Save to web/
  File('web/icons/Icon-512.png').writeAsBytesSync(img.encodePng(icon512));
  File('web/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(icon512));
  File('web/icons/Icon-192.png').writeAsBytesSync(img.encodePng(icon192));
  File('web/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(icon192));
  File('web/favicon.png').writeAsBytesSync(img.encodePng(favicon));

  // Save to public/web/
  File('public/web/icons/Icon-512.png').writeAsBytesSync(img.encodePng(icon512));
  File('public/web/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(icon512));
  File('public/web/icons/Icon-192.png').writeAsBytesSync(img.encodePng(icon192));
  File('public/web/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(icon192));
  File('public/web/favicon.png').writeAsBytesSync(img.encodePng(favicon));

  print('Successfully generated light-background web icons and favicon!');
}
