import 'dart:io';
import 'dart:ui' as ui;

/// Entity representing an image file with its UI representation
class ImageEntity {
  final File file;
  final ui.Image? uiImage;

  const ImageEntity({
    required this.file,
    this.uiImage,
  });
}
