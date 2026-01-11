import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';

/// Data source for image picking operations
class ImagePickerDataSource {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from the specified source
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Load UI image from file bytes
  Future<ui.Image?> loadUiImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      throw Exception('Failed to load UI image: $e');
    }
  }
}
