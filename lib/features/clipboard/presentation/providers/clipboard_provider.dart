import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/copy_text_usecase.dart';
import 'usecase_providers.dart';

/// Provider for clipboard operations
class ClipboardNotifier {
  final CopyTextUseCase _copyTextUseCase;

  ClipboardNotifier(this._copyTextUseCase);

  /// Copy text to clipboard
  Future<void> copyText(String text) async {
    try {
      await _copyTextUseCase(text);
    } catch (e) {
      throw Exception('Failed to copy text: $e');
    }
  }
}

final clipboardNotifierProvider = Provider<ClipboardNotifier>((ref) {
  final useCase = ref.watch(copyTextUseCaseProvider);
  return ClipboardNotifier(useCase);
});
