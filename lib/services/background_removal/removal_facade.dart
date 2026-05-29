import 'dart:io';
import 'removal_service.dart';

class BackgroundRemovalFacade {
  final BackgroundRemovalService _service = BackgroundRemovalService();

  Future<File> removeBackground(File inputImage) async {
    return _service.removeBackground(inputImage);
  }
}
