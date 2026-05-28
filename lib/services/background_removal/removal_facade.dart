import 'dart:io';
import '../image_sticker_service.dart';
import 'simple_remover.dart';
import '../../core/utils/logger.dart';

/// 背景去除门面
///
/// 主方案: ML Kit 主体分割 + 贴纸描边效果 (ImageStickerService)
/// 降级方案: 基于边缘检测的简单背景去除 (SimpleBackgroundRemover)
class BackgroundRemovalFacade {
  final ImageStickerService _sticker;
  final SimpleBackgroundRemover _fallback = SimpleBackgroundRemover();

  BackgroundRemovalFacade({
    int strokeWidth = 12,
  }) : _sticker = ImageStickerService(strokeWidth: strokeWidth);

  Future<File> removeBackground(File inputImage) async {
    try {
      // 主方案: ML Kit 分割 + 贴纸效果
      final result = await _sticker.processImageToSticker(inputImage);
      if (result != null) {
        AppLogger.info('Sticker effect applied successfully');
        return result;
      }
    } catch (e) {
      AppLogger.warn('Sticker processing failed, falling back: $e');
    }

    // 降级: 简单背景去除
    try {
      return await _fallback.removeBackground(inputImage);
    } catch (e) {
      AppLogger.warn('Fallback removal also failed: $e');
      rethrow;
    }
  }
}
