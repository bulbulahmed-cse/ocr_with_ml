import '../entities/image_entity.dart';
import '../entities/text_block_entity.dart';
import '../repositories/text_recognition_repository.dart';

/// Use case for processing an image to extract text
class ProcessImageUseCase {
  final TextRecognitionRepository _textRecognitionRepository;

  ProcessImageUseCase(this._textRecognitionRepository);

  Future<Map> call(ImageEntity image) async {
    return await _textRecognitionRepository.recognizeText(image);
  }
}
