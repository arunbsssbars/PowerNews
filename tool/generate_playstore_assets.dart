import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Generating Google Play Store graphic assets...');

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

  // 1. Google Play Store High-Res Icon (512x512)
  final icon512 = img.copyResize(
    sourceImg,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.linear,
  );
  File('builds/playstore/app_icon_512.png').writeAsBytesSync(img.encodePng(icon512));
  print('Generated builds/playstore/app_icon_512.png');

  // 2. Google Play Store Feature Graphic (1024x500)
  // Background: Rich Brand Navy #0B1528 (R: 11, G: 21, B: 40)
  final featureGraphic = img.Image(width: 1024, height: 500);
  final bgColor = img.ColorRgb8(11, 21, 40);
  img.fill(featureGraphic, color: bgColor);

  // Place rounded app icon in center of feature graphic (height: 280, width: 280)
  final icon280 = img.copyResize(
    sourceImg,
    width: 280,
    height: 280,
    interpolation: img.Interpolation.linear,
  );

  final dstX = (1024 - 280) ~/ 2;
  final dstY = (500 - 280) ~/ 2;
  img.compositeImage(featureGraphic, icon280, dstX: dstX, dstY: dstY);

  File('builds/playstore/feature_graphic_1024x500.png').writeAsBytesSync(img.encodePng(featureGraphic));
  print('Generated builds/playstore/feature_graphic_1024x500.png');

  print('All Google Play Store assets successfully created in builds/playstore/ !');
}
