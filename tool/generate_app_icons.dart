import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final sourceBytes = File('assets/images/kkopi_logo.png').readAsBytesSync();
  final sourceImage = img.decodeImage(sourceBytes);
  if (sourceImage == null) {
    throw const FormatException('Unable to decode the provided logo.');
  }
  final croppedLogo = _cropToArtwork(sourceImage);

  void writePng(String path, int size) {
    final resized = img.copyResize(
      croppedLogo,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(resized));
  }

  for (final entry in {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  }.entries) {
    writePng(
      'android/app/src/main/res/${entry.key}/ic_launcher.png',
      entry.value,
    );
  }

  for (final assetSet in [
    'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    'macos/Runner/Assets.xcassets/AppIcon.appiconset',
  ]) {
    final contents =
        jsonDecode(File('$assetSet/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final image in contents['images'] as List<dynamic>) {
      final item = image as Map<String, dynamic>;
      final filename = item['filename'] as String?;
      if (filename == null) continue;

      final dimensions = (item['size'] as String).split('x');
      final logicalSize = double.parse(dimensions.first);
      final scale = double.parse((item['scale'] as String).replaceAll('x', ''));
      writePng('$assetSet/$filename', (logicalSize * scale).round());
    }
  }

  for (final size in [192, 512]) {
    writePng('web/icons/Icon-$size.png', size);
    writePng('web/icons/Icon-maskable-$size.png', size);
  }
  writePng('web/favicon.png', 32);

  final windowsIcon = img.copyResize(
    croppedLogo,
    width: 256,
    height: 256,
    interpolation: img.Interpolation.average,
  );
  File(
    'windows/runner/resources/app_icon.ico',
  ).writeAsBytesSync(img.encodeIco(windowsIcon, singleFrame: true));
}

img.Image _cropToArtwork(img.Image source) {
  var left = source.width;
  var top = source.height;
  var right = -1;
  var bottom = -1;

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final isBackground = pixel.r >= 245 && pixel.g >= 245 && pixel.b >= 245;
      if (isBackground) continue;

      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }

  if (right < left || bottom < top) {
    throw const FormatException('The logo artwork could not be detected.');
  }

  final contentWidth = right - left + 1;
  final contentHeight = bottom - top + 1;
  final cropSize =
      ([
                contentWidth,
                contentHeight,
              ].reduce((first, second) => first > second ? first : second) *
              1.06)
          .ceil();
  final centerX = (left + right) ~/ 2;
  final centerY = (top + bottom) ~/ 2;
  final cropLeft = (centerX - cropSize ~/ 2).clamp(0, source.width - cropSize);
  final cropTop = (centerY - cropSize ~/ 2).clamp(0, source.height - cropSize);

  return img.copyCrop(
    source,
    x: cropLeft,
    y: cropTop,
    width: cropSize,
    height: cropSize,
  );
}
