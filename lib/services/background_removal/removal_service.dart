import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class BackgroundRemovalService {
  Future<File> removeBackground(File inputImage) async {
    final bytes = await inputImage.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('图片解码失败');

    final target = image.width > 1024
        ? img.copyResize(image, width: 1024)
        : image;

    final w = target.width;
    final h = target.height;

    final bgColor = _detectBackground(target);
    final threshold = _adaptiveThreshold(target, bgColor);

    // 前景 mask
    final mask = List.filled(w * h, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = target.getPixel(x, y);
        mask[y * w + x] = _dist(p, bgColor) >= threshold;
      }
    }

    // 膨胀做描边
    const strokeW = 3;
    final dilated = _dilate(mask, w, h, strokeW);

    final pad = strokeW + 2;
    final out = img.Image(width: w + pad * 2, height: h + pad * 2);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        final dx = x + pad;
        final dy = y + pad;

        if (mask[idx]) {
          final p = target.getPixel(x, y);
          out.setPixelRgba(dx, dy, p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt());
        } else if (dilated[idx]) {
          out.setPixelRgba(dx, dy, 255, 255, 255, 255);
        }
      }
    }

    final outputPath = inputImage.path.replaceAll(
      RegExp(r'\.\w+$', caseSensitive: false),
      '_sticker.png',
    );
    await File(outputPath).writeAsBytes(img.encodePng(out));
    return File(outputPath);
  }

  int _detectBackground(img.Image image) {
    int sr = 0, sg = 0, sb = 0, count = 0;

    void sample(int x, int y) {
      final p = image.getPixel(x, y);
      sr += p.r.toInt(); sg += p.g.toInt(); sb += p.b.toInt(); count++;
    }

    // 四角
    sample(0, 0);
    sample(image.width - 1, 0);
    sample(0, image.height - 1);
    sample(image.width - 1, image.height - 1);

    // 四边
    for (int x = 0; x < image.width; x += 15) { sample(x, 0); sample(x, image.height - 1); }
    for (int y = 0; y < image.height; y += 15) { sample(0, y); sample(image.width - 1, y); }

    // 返回 RGB 整数值（打包为单 int 方便比较）
    return ((sr ~/ count) << 16) | ((sg ~/ count) << 8) | (sb ~/ count);
  }

  int _adaptiveThreshold(img.Image image, int bgRgb) {
    final br = (bgRgb >> 16) & 0xFF;
    final bg = (bgRgb >> 8) & 0xFF;
    final bb = bgRgb & 0xFF;

    final dists = <int>[];
    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final p = image.getPixel(x, y);
        final dr = p.r.toInt() - br;
        final dg = p.g.toInt() - bg;
        final db = p.b.toInt() - bb;
        dists.add(dr * dr + dg * dg + db * db);
      }
    }
    dists.sort();
    final median = dists[dists.length ~/ 2];
    return max(900, (median * 0.35).toInt());
  }

  int _dist(img.Pixel p, int bgRgb) {
    final br = (bgRgb >> 16) & 0xFF;
    final bg = (bgRgb >> 8) & 0xFF;
    final bb = bgRgb & 0xFF;
    final dr = p.r.toInt() - br;
    final dg = p.g.toInt() - bg;
    final db = p.b.toInt() - bb;
    return dr * dr + dg * dg + db * db;
  }

  List<bool> _dilate(List<bool> mask, int w, int h, int r) {
    final result = List<bool>.filled(w * h, false);
    for (int y = r; y < h - r; y++) {
      for (int x = r; x < w - r; x++) {
        if (mask[y * w + x]) continue;
        for (int dy = -r; dy <= r; dy++) {
          for (int dx = -r; dx <= r; dx++) {
            if (mask[(y + dy) * w + (x + dx)]) {
              result[y * w + x] = true;
              dy = r + 1; // break outer
              break;
            }
          }
        }
      }
    }
    return result;
  }
}
