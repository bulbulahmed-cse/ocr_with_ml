import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../domain/usecases/generate_pdf_usecase.dart';
import '../../../ocr/presentation/providers/ocr_state_provider.dart';
import 'usecase_providers.dart';

/// State for PDF generation
class PdfState {
  final bool isGenerating;
  final String? errorMessage;

  const PdfState({
    this.isGenerating = false,
    this.errorMessage,
  });

  PdfState copyWith({
    bool? isGenerating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PdfState(
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for PDF operations
class PdfNotifier extends StateNotifier<PdfState> {
  final GeneratePdfUseCase _generatePdfUseCase;
  final Ref _ref;

  PdfNotifier({
    required GeneratePdfUseCase generatePdfUseCase,
    required Ref ref,
  })  : _generatePdfUseCase = generatePdfUseCase,
        _ref = ref,
        super(const PdfState());

  /// Generate PDF from current image and text blocks
  Future<void> generatePdf() async {
    final ocrState = _ref.read(ocrNotifierProvider);
    final image = ocrState.image;
    final textBlocks = ocrState.textBlocks;

    if (image == null || textBlocks.isEmpty || image.uiImage == null) {
      state = state.copyWith(
        errorMessage: 'Image and text blocks are required',
      );
      return;
    }

    try {
      state = state.copyWith(isGenerating: true, clearError: true);

      final pdfBytes = await _generatePdfUseCase(
        image: image,
        textBlocks: textBlocks,
      );

      state = state.copyWith(isGenerating: false);

      // Show PDF preview and print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Failed to generate PDF: $e',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final pdfNotifierProvider = StateNotifierProvider<PdfNotifier, PdfState>((ref) {
  return PdfNotifier(
    generatePdfUseCase: ref.watch(generatePdfUseCaseProvider),
    ref: ref,
  );
});
