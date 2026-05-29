import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;

class AssetStickerService {
  final int maxWidth;
  final int strokeWidth;

  AssetStickerService({this.maxWidth = 1024, this.strokeWidth = 8});

  Future<File?> process(File inputImage) async {
    try {
      final rawBytes = await inputImage.readAsBytes();
      var image = img.decodeImage(rawBytes);
      if (image == null) {
        return null;
      }
      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }
      final w = image.width, h = image.height;

      // ===== ML Kit 前景位图（使用缩放后的图，保证尺寸一致） =====
      final rgba = Uint8List.fromList(
        image.getBytes(order: img.ChannelOrder.rgba),
      );
      Uint8List? fgBitmap;
      try {
        final s = SubjectSegmenter(
          options: SubjectSegmenterOptions(
            enableForegroundBitmap: true,
            enableForegroundConfidenceMask: false,
            enableMultipleSubjects: SubjectResultOptions(
              enableConfidenceMask: false,
              enableSubjectBitmap: false,
            ),
          ),
        );
        // 用缩放后图片的 PNG bytes 作为输入，保证 ML Kit 输出尺寸一致
        final scaledBytes = Uint8List.fromList(img.encodePng(image));
        final scaledFile = File('${inputImage.path}_scaled.png');
        await scaledFile.writeAsBytes(scaledBytes);
        final r = await s.processImage(
          InputImage.fromFilePath(scaledFile.path),
        );
        await scaledFile.delete();
        await s.close();
        fgBitmap = r.foregroundBitmap;
        debugPrint(
          'ML Kit OK: fgBitmap ${fgBitmap?.length} bytes, image ${w}x$h',
        );
      } catch (e) {
        debugPrint('ML Kit fail: $e');
      }

      // ===== Isolate =====
      final resultBytes = await Isolate.run(
        () => _worker(rgba, fgBitmap, w, h, strokeWidth),
      );

      final out = inputImage.path.replaceAll(RegExp(r'\.\w+$'), '_sticker.png');
      await File(out).writeAsBytes(resultBytes);
      return File(out);
    } catch (e) {
      debugPrint('Sticker: $e');
      return null;
    }
  }
}

Uint8List _worker(Uint8List rgba, Uint8List? fgBytes, int w, int h, int r) {
  final src = img.Image.fromBytes(
    width: w,
    height: h,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  List<bool> mask;
  if (fgBytes != null) {
    // ML Kit 返回的位图可能是不同尺寸（模型内部分辨率限制），先解码再缩放到目标尺寸
    final rawFg = img.decodeImage(fgBytes);
    if (rawFg != null && rawFg.width > 0 && rawFg.height > 0) {
      final fgImg = (rawFg.width != w || rawFg.height != h)
          ? img.copyResize(rawFg, width: w, height: h)
          : rawFg;
      int fgCount = 0;
      mask = List<bool>.filled(w * h, false);
      for (int i = 0; i < w * h; i++) {
        if (fgImg.getPixel(i % w, i ~/ w).a > 10) {
          mask[i] = true;
          fgCount++;
        }
      }
      if (fgCount < w * h * 0.03) mask = _fallbackMask(src, w, h);
    } else {
      mask = _fallbackMask(src, w, h);
    }
  } else {
    mask = _fallbackMask(src, w, h);
  }

  // ----- white stroke + layered soft shadow on a transparent canvas -----
  final whiteStroke = _dilate(mask, w, h, r);
  final nearShadow = _dilate(mask, w, h, r + 5);
  final midShadow = _dilate(mask, w, h, r + 10);
  final farShadow = _dilate(mask, w, h, r + 16);

  final pad = r + 26;
  final out = img.Image(
    width: w + pad * 2,
    height: h + pad * 2,
    numChannels: 4,
  );
  img.fill(out, color: img.ColorRgba8(0, 0, 0, 0));

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = y * w + x, dx = x + pad, dy = y + pad;

      if (farShadow[i] && !mask[i]) {
        out.setPixelRgba(dx + 10, dy + 12, 0, 0, 0, 24);
      }
      if (midShadow[i] && !mask[i]) {
        out.setPixelRgba(dx + 7, dy + 8, 0, 0, 0, 42);
      }
      if (nearShadow[i] && !mask[i]) {
        out.setPixelRgba(dx + 4, dy + 5, 0, 0, 0, 72);
      }

      // 白描边（中间层，覆盖阴影）
      if (whiteStroke[i] && !mask[i]) {
        out.setPixelRgba(dx, dy, 255, 255, 255, 255);
      }

      // 前景（最上层）
      if (mask[i]) {
        final p = src.getPixel(x, y);
        out.setPixelRgba(
          dx,
          dy,
          p.r.toInt(),
          p.g.toInt(),
          p.b.toInt(),
          p.a.toInt(),
        );
      }
    }
  }
  return Uint8List.fromList(img.encodePng(out));
}

// ============================================================
List<bool> _dilate(List<bool> m, int w, int h, int r) {
  final d = List<bool>.filled(w * h, false);
  for (int y = r; y < h - r; y++) {
    for (int x = r; x < w - r; x++) {
      if (m[y * w + x]) continue;
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (m[(y + dy) * w + (x + dx)]) {
            d[y * w + x] = true;
            dy = r + 1;
            break;
          }
        }
      }
    }
  }
  return d;
}

List<bool> _fallbackMask(img.Image src, int w, int h) {
  int sr = 0, sg = 0, sb = 0, cnt = 0;
  for (int x = 0; x < w; x++) {
    for (int y in [0, h - 1]) {
      final p = src.getPixel(x, y);
      sr += p.r.toInt();
      sg += p.g.toInt();
      sb += p.b.toInt();
      cnt++;
    }
  }
  for (int y = 0; y < h; y++) {
    for (int x in [0, w - 1]) {
      final p = src.getPixel(x, y);
      sr += p.r.toInt();
      sg += p.g.toInt();
      sb += p.b.toInt();
      cnt++;
    }
  }
  final br = sr ~/ cnt, bg = sg ~/ cnt, bb = sb ~/ cnt;
  int v = 0, m = 0;
  for (int x = 5; x < w - 5; x += 10) {
    for (int y in [0, h - 1]) {
      final p = src.getPixel(x, y);
      final dr = p.r.toInt() - br, dg = p.g.toInt() - bg, db = p.b.toInt() - bb;
      v += dr * dr + dg * dg + db * db;
      m++;
    }
  }
  for (int y = 5; y < h - 5; y += 10) {
    for (int x in [0, w - 1]) {
      final p = src.getPixel(x, y);
      final dr = p.r.toInt() - br, dg = p.g.toInt() - bg, db = p.b.toInt() - bb;
      v += dr * dr + dg * dg + db * db;
      m++;
    }
  }
  if (m > 0) v ~/= m;
  final threshold = (v * 3).clamp(2500, 40000);

  final visited = List.filled(w * h, false);
  final queue = <int>[];
  void enq(int x, int y) {
    if (x < 0 || x >= w || y < 0 || y >= h) return;
    final i = y * w + x;
    if (visited[i]) return;
    final p = src.getPixel(x, y);
    final dr = p.r.toInt() - br, dg = p.g.toInt() - bg, db = p.b.toInt() - bb;
    if (dr * dr + dg * dg + db * db < threshold) {
      visited[i] = true;
      queue.add(i);
    }
  }

  for (int x = 0; x < w; x++) {
    enq(x, 0);
    enq(x, h - 1);
  }
  for (int y = 0; y < h; y++) {
    enq(0, y);
    enq(w - 1, y);
  }
  for (int i = 0; i < queue.length; i++) {
    final idx = queue[i];
    enq(idx % w - 1, idx ~/ w);
    enq(idx % w + 1, idx ~/ w);
    enq(idx % w, idx ~/ w - 1);
    enq(idx % w, idx ~/ w + 1);
  }
  final mask = List<bool>.filled(w * h, false);
  for (int i = 0; i < w * h; i++) {
    mask[i] = !visited[i];
  }
  return mask;
}
