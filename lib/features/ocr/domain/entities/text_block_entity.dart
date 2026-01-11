import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Entity representing a detected text block
class TextBlockEntity {
  final String text;
  final ui.Rect boundingBox;
  final List<TextLine> lines;

  const TextBlockEntity({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });

  factory TextBlockEntity.fromTextBlock(TextBlock block) {
    return TextBlockEntity(
      text: block.text,
      boundingBox: block.boundingBox,
      lines: block.lines,
    );
  }
}
