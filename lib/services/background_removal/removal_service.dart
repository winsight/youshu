import 'dart:io';

abstract class BackgroundRemovalService {
  Future<File> removeBackground(File inputImage);
}
