import 'dart:io';
import '../asset_sticker_service.dart';
import 'removal_service.dart';

class BackgroundRemovalFacade {
  final AssetStickerService _sticker = AssetStickerService();
  final BackgroundRemovalService _fallback = BackgroundRemovalService();

  Future<File> removeBackground(File inputImage) async {
    // Primary: ML Kit + Isolate sticker pipeline
    final result = await _sticker.process(inputImage);
    if (result != null) return result;

    // Fallback: pure Dart color-based removal
    return _fallback.removeBackground(inputImage);
  }
}
