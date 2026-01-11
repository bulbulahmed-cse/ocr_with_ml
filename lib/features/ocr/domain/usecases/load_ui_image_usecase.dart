import 'dart:io';
import 'dart:ui' as ui;
import '../repositories/image_repository.dart';

/// Use case for loading UI image from file
class LoadUiImageUseCase {
  final ImageRepository _imageRepository;

  LoadUiImageUseCase(this._imageRepository);

  Future<ui.Image?> call(File file) async {
    return await _imageRepository.loadUiImage(file);
  }
}
