import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/mlkit_datasource.dart';
import '../../domain/entities/image_entity.dart';
import '../../domain/entities/text_block_entity.dart';
import '../../domain/usecases/load_ui_image_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import '../../domain/usecases/process_image_usecase.dart';
import 'usecase_providers.dart';

/// State class for OCR screen
class OcrState {
  final ImageEntity? image;
  final List<TextBlockEntity> textBlocks;
  final bool isProcessing;
  final double scale;
  final String? errorMessage;
  final RecognitionScript recognitionScript;

  const OcrState({
    this.image,
    this.textBlocks = const [],
    this.isProcessing = false,
    this.scale = 1.0,
    this.errorMessage,
    this.recognitionScript = RecognitionScript.latin,
  });

  OcrState copyWith({
    ImageEntity? image,
    List<TextBlockEntity>? textBlocks,
    bool? isProcessing,
    double? scale,
    String? errorMessage,
    RecognitionScript? recognitionScript,
    bool clearError = false,
  }) {
    return OcrState(
      image: image ?? this.image,
      textBlocks: textBlocks ?? this.textBlocks,
      isProcessing: isProcessing ?? this.isProcessing,
      scale: scale ?? this.scale,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recognitionScript: recognitionScript ?? this.recognitionScript,
    );
  }

  bool get hasImage => image != null;
  bool get hasTextBlocks => textBlocks.isNotEmpty;
}

/// Provider for OCR state management
class OcrNotifier extends StateNotifier<OcrState> {
  final PickImageUseCase _pickImageUseCase;
  final LoadUiImageUseCase _loadUiImageUseCase;
  final ProcessImageUseCase _processImageUseCase;

  OcrNotifier({
    required PickImageUseCase pickImageUseCase,
    required LoadUiImageUseCase loadUiImageUseCase,
    required ProcessImageUseCase processImageUseCase,
  })  : _pickImageUseCase = pickImageUseCase,
        _loadUiImageUseCase = loadUiImageUseCase,
        _processImageUseCase = processImageUseCase,
        super(const OcrState());

  /// Pick an image from the specified source
  Future<void> pickImage(ImageSource source) async {
    try {
      state = state.copyWith(isProcessing: true, clearError: true);

      final imageEntity = await _pickImageUseCase(source);
      if (imageEntity == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      state = state.copyWith(
        image: imageEntity,
        textBlocks: [],
        scale: 1.0,
        isProcessing: false,
      );

      // Load UI image and process
      await loadUiImageAndProcess(imageEntity);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to pick image: $e',
      );
    }
  }

  /// Load UI image and process for text recognition
  Future<void> loadUiImageAndProcess(ImageEntity imageEntity) async {
    try {
      state = state.copyWith(isProcessing: true, clearError: true);

      // Load UI image
      final uiImage = await _loadUiImageUseCase(imageEntity.file);
      if (uiImage == null) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Failed to load image',
        );
        return;
      }

      // Update image with UI image
      final updatedImage = ImageEntity(
        file: imageEntity.file,
        uiImage: uiImage,
      );

      // Process image for text recognition
      final textBlocks = await _processImageUseCase(updatedImage);

      state = state.copyWith(
        image: updatedImage,
        textBlocks: textBlocks,
        isProcessing: false,
      );

      if (textBlocks.isEmpty) {
        state = state.copyWith(
          errorMessage: 'No text detected in image',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to process image: $e',
      );
    }
  }

  /// Update zoom scale
  void updateScale(double newScale) {
    state = state.copyWith(scale: newScale.clamp(0.5, 3.0));
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Change recognition script and re-process image if available
  Future<void> changeScript(RecognitionScript script) async {
    if (state.recognitionScript == script) return;
    
    state = state.copyWith(recognitionScript: script);
    
    // Re-process image if available
    if (state.hasImage) {
      await loadUiImageAndProcess(state.image!);
    }
  }

  /// Reset state
  void reset() {
    state = const OcrState();
  }
}

final ocrNotifierProvider =
    StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  return OcrNotifier(
    pickImageUseCase: ref.watch(pickImageUseCaseProvider),
    loadUiImageUseCase: ref.watch(loadUiImageUseCaseProvider),
    processImageUseCase: ref.watch(processImageUseCaseProvider),
  );
});
