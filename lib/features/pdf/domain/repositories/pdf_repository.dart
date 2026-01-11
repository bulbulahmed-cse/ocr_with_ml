import 'dart:typed_data';
import '../../../ocr/domain/entities/image_entity.dart';
import '../../../ocr/domain/entities/text_block_entity.dart';

/// Repository interface for PDF operations
abstract class PdfRepository {
  /// Generate PDF from image and text blocks
  Future<Uint8List> generatePdf({
    required ImageEntity image,
    required List<TextBlockEntity> textBlocks,
  });
}
