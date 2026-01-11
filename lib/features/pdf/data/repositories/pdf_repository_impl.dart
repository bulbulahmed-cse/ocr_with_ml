import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../ocr/domain/entities/image_entity.dart';
import '../../../ocr/domain/entities/text_block_entity.dart';
import '../../domain/repositories/pdf_repository.dart';
import '../datasources/pdf_datasource.dart';

/// Implementation of PdfRepository
class PdfRepositoryImpl implements PdfRepository {
  final PdfDataSource _dataSource;

  PdfRepositoryImpl(this._dataSource);

  @override
  Future<Uint8List> generatePdf({
    required ImageEntity image,
    required List<TextBlockEntity> textBlocks,
  }) async {
    if (image.uiImage == null) {
      throw Exception('UI image is required for PDF generation');
    }

    try {
      // Convert TextBlockEntity list to TextBlock list for PDF generation
      // Since we need the TextBlock type for the PDF datasource
      final textBlocksForPdf = textBlocks.map((entity) {
        // Create a synthetic TextBlock-like object
        return _createSyntheticTextBlock(entity);
      }).toList();

      return await _dataSource.generatePdf(
        imageFile: image.file,
        uiImage: image.uiImage!,
        textBlocks: textBlocksForPdf,
      );
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  // Helper method to create a compatible object for PDF generation
  // This maintains the interface needed by PdfDataSource
  dynamic _createSyntheticTextBlock(TextBlockEntity entity) {
    return _SyntheticTextBlock(
      text: entity.text,
      boundingBox: entity.boundingBox,
    );
  }
}

// Synthetic class to hold text block data for PDF generation
class _SyntheticTextBlock {
  final String text;
  final ui.Rect boundingBox;

  _SyntheticTextBlock({
    required this.text,
    required this.boundingBox,
  });
}
