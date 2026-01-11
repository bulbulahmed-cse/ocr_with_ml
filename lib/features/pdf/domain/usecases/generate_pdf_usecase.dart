import 'dart:typed_data';
import '../../../ocr/domain/entities/image_entity.dart';
import '../../../ocr/domain/entities/text_block_entity.dart';
import '../repositories/pdf_repository.dart';

/// Use case for generating a PDF from image and text blocks
class GeneratePdfUseCase {
  final PdfRepository _pdfRepository;

  GeneratePdfUseCase(this._pdfRepository);

  Future<Uint8List> call({
    required ImageEntity image,
    required List<TextBlockEntity> textBlocks,
  }) async {
    return await _pdfRepository.generatePdf(
      image: image,
      textBlocks: textBlocks,
    );
  }
}
