import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;

/// ML Kit 主体分割 + 描边 → "贴纸效果" 透明 PNG
class ImageStickerService {
  final SubjectSegmenter _segmenter;
  final img.Color strokeColor;
  final int strokeWidth;

  ImageStickerService({
    img.Color? strokeColor,
    this.strokeWidth = 12,
  }) : strokeColor = strokeColor ?? img.ColorRgba8(255, 255, 255, 255),
       _segmenter = SubjectSegmenter(
         options: SubjectSegmenterOptions(
           enableForegroundBitmap: true,
           enableForegroundConfidenceMask: true,
           enableMultipleSubjects: SubjectResultOptions(
             enableConfidenceMask: false,
             enableSubjectBitmap: false,
           ),
         ),
       );

  Future<File?> processImageToSticker(File inputImage) async {
    try {
      final inputBytes = await inputImage.readAsBytes();
      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) throw Exception('图片解码失败');
      final imgW = decoded.width;
      final imgH = decoded.height;

      final input = InputImage.fromFilePath(inputImage.path);
      final mask = await _segmenter.processImage(input);
      await _segmenter.close();

      final fgBitmap = mask.foregroundBitmap;
      if (fgBitmap == null) throw Exception('foregroundBitmap 为 null');

      final fgImage = img.Image.fromBytes(
        width: imgW, height: imgH,
        bytes: fgBitmap.buffer, numChannels: 4,
      );

      final boolMask = List<bool>.filled(imgW * imgH, false);
      for (int y = 0; y < imgH; y++) {
        for (int x = 0; x < imgW; x++) {
          boolMask[y * imgW + x] = fgImage.getPixel(x, y).a > 0;
        }
      }

      final dilatedMask = _dilate(boolMask, imgW, imgH, strokeWidth);

      final pad = strokeWidth + 4;
      final canvasW = imgW + pad * 2;
      final canvasH = imgH + pad * 2;
      final canvas = img.Image(width: canvasW, height: canvasH);

      for (int y = 0; y < imgH; y++) {
        for (int x = 0; x < imgW; x++) {
          final dx = x + pad;
          final dy = y + pad;
          final idx = y * imgW + x;
          if (boolMask[idx]) {
            final src = fgImage.getPixel(x, y);
            canvas.setPixelRgba(dx, dy, src.r.toInt(), src.g.toInt(),
                src.b.toInt(), src.a.toInt());
          } else if (dilatedMask[idx]) {
            canvas.setPixelRgba(dx, dy, strokeColor.r.toInt(),
                strokeColor.g.toInt(), strokeColor.b.toInt(), strokeColor.a.toInt());
          }
        }
      }

      final outputPath = inputImage.path.replaceAll(
        RegExp(r'\.\w+$', caseSensitive: false), '_sticker.png');
      await File(outputPath).writeAsBytes(img.encodePng(canvas));
      return File(outputPath);
    } catch (e) {
      debugPrint('ImageStickerService error: $e');
      return null;
    }
  }

  List<bool> _dilate(List<bool> mask, int w, int h, int radius) {
    final result = List<bool>.filled(w * h, false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        bool found = false;
        for (int dy = -radius; dy <= radius && !found; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          final maxDxSq = radius * radius - dy * dy;
          if (maxDxSq < 0) continue;
          final maxDx = _isqrt(maxDxSq);
          for (int dx = -maxDx; dx <= maxDx; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= w) continue;
            if (mask[ny * w + nx]) {
              result[y * w + x] = true;
              found = true;
              break;
            }
          }
        }
      }
    }
    return result;
  }

  int _isqrt(int n) {
    if (n <= 1) return n;
    var x0 = n ~/ 2, x1 = (x0 + n ~/ x0) ~/ 2;
    while (x1 < x0) { x0 = x1; x1 = (x0 + n ~/ x0) ~/ 2; }
    return x0;
  }
}

void debugPrint(String msg) {
  // ignore: avoid_print
  print('[ImageSticker] $msg');
}
