import '../../domain/entities/image_entity.dart';
import '../../domain/entities/text_block_entity.dart';
import '../../domain/repositories/text_recognition_repository.dart';
import '../datasources/mlkit_datasource.dart';
import '../models/text_block_model.dart';

/// Implementation of TextRecognitionRepository
class TextRecognitionRepositoryImpl implements TextRecognitionRepository {
  final MlKitDataSource _dataSource;

  TextRecognitionRepositoryImpl(this._dataSource);

  @override
  Future<List<TextBlockEntity>> recognizeText(ImageEntity image) async {
    try {
      final textBlocks = await _dataSource.recognizeText(image.file);
      return textBlocks
          .map((block) => TextBlockModel.fromTextBlock(block))
          .toList();
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  @override
  void dispose() {
    _dataSource.dispose();
  }
}
