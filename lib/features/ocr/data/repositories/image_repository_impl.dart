import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/image_entity.dart';
import '../../domain/repositories/image_repository.dart';
import '../datasources/image_picker_datasource.dart';

/// Implementation of ImageRepository
class ImageRepositoryImpl implements ImageRepository {
  final ImagePickerDataSource _dataSource;

  ImageRepositoryImpl(this._dataSource);

  @override
  Future<ImageEntity?> pickImage(ImageSource source) async {
    try {
      final file = await _dataSource.pickImage(source);
      if (file == null) return null;

      return ImageEntity(file: file);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  @override
  Future<ui.Image?> loadUiImage(File file) async {
    try {
      return await _dataSource.loadUiImage(file);
    } catch (e) {
      throw Exception('Failed to load UI image: $e');
    }
  }
}
