import 'dart:io';
import 'package:image/image.dart' as img;
import 'removal_service.dart';
import '../../core/utils/logger.dart';

class SimpleBackgroundRemover implements BackgroundRemovalService {
  @override
  Future<File> removeBackground(File inputImage) async {
    final bytes = await inputImage.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize for processing speed
    final resized = img.copyResize(image, width: 512);

    // Simple edge-based background detection
    // Find the dominant background color from corners
    final bgColor = _detectBackgroundColor(resized);

    // Create mask and remove similar colors
    const tolerance = 60;
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        if (_colorDistance(pixel, bgColor) < tolerance) {
          resized.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    // Save result
    final outputPath = inputImage.path.replaceAll(
      RegExp(r'\.\w+$'),
      '_bg_removed.png',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodePng(resized));

    AppLogger.info('Background removal completed: $outputPath');
    return outputFile;
  }

  img.Color _detectBackgroundColor(img.Image image) {
    // Sample corners and edges to find dominant background
    final samples = <img.Color>[];
    final corners = [
      (0, 0),
      (image.width - 1, 0),
      (0, image.height - 1),
      (image.width - 1, image.height - 1),
    ];

    for (final (x, y) in corners) {
      samples.add(image.getPixel(x, y));
    }

    // Edge samples
    for (int x = 0; x < image.width; x += 10) {
      samples.add(image.getPixel(x, 0));
      samples.add(image.getPixel(x, image.height - 1));
    }
    for (int y = 0; y < image.height; y += 10) {
      samples.add(image.getPixel(0, y));
      samples.add(image.getPixel(image.width - 1, y));
    }

    // Average
    int r = 0, g = 0, b = 0;
    for (final c in samples) {
      r += c.r.toInt();
      g += c.g.toInt();
      b += c.b.toInt();
    }
    return img.ColorRgba8(
      r ~/ samples.length,
      g ~/ samples.length,
      b ~/ samples.length,
      255,
    );
  }

  double _colorDistance(img.Color a, img.Color b) {
    final dr = a.r.toInt() - b.r.toInt();
    final dg = a.g.toInt() - b.g.toInt();
    final db = a.b.toInt() - b.b.toInt();
    return (dr * dr + dg * dg + db * db).toDouble();
  }
}
