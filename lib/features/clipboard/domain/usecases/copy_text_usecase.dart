import '../repositories/clipboard_repository.dart';

/// Use case for copying text to clipboard
class CopyTextUseCase {
  final ClipboardRepository _clipboardRepository;

  CopyTextUseCase(this._clipboardRepository);

  Future<void> call(String text) async {
    return await _clipboardRepository.copyText(text);
  }
}
