import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../entities/image_entity.dart';

/// Repository interface for image operations
abstract class ImageRepository {
  /// Pick an image from the specified source
  Future<ImageEntity?> pickImage(ImageSource source);

  /// Load UI image from file
  Future<ui.Image?> loadUiImage(File file);
}
