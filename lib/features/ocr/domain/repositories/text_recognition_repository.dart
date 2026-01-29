import '../entities/text_block_entity.dart';
import '../entities/image_entity.dart';

/// Repository interface for text recognition operations
abstract class TextRecognitionRepository {
  /// Process image and extract text blocks
  Future<Map> recognizeText(ImageEntity image);

  /// Dispose resources
  void dispose();
}
