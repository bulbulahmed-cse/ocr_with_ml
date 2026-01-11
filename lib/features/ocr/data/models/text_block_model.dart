import '../../domain/entities/text_block_entity.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Model for text block data
class TextBlockModel extends TextBlockEntity {
  const TextBlockModel({
    required super.text,
    required super.boundingBox,
    required super.lines,
  });

  factory TextBlockModel.fromEntity(TextBlockEntity entity) {
    return TextBlockModel(
      text: entity.text,
      boundingBox: entity.boundingBox,
      lines: entity.lines,
    );
  }

  factory TextBlockModel.fromTextBlock(TextBlock block) {
    return TextBlockModel(
      text: block.text,
      boundingBox: block.boundingBox,
      lines: block.lines,
    );
  }
}
