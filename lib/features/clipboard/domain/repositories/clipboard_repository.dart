/// Repository interface for clipboard operations
abstract class ClipboardRepository {
  /// Copy text to clipboard
  Future<void> copyText(String text);
}
