import 'dart:io';
import 'simple_remover.dart';
import '../../core/utils/logger.dart';

class BackgroundRemovalFacade {
  final SimpleBackgroundRemover _local = SimpleBackgroundRemover();

  Future<File> removeBackground(File inputImage) async {
    try {
      return await _local.removeBackground(inputImage);
    } catch (e) {
      AppLogger.warn('Background removal failed: $e');
      rethrow;
    }
  }
}
