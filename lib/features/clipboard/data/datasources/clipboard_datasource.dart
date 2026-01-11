import 'package:flutter/services.dart';

/// Data source for clipboard operations
class ClipboardDataSource {
  /// Copy text to clipboard
  Future<void> copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      throw Exception('Failed to copy text: $e');
    }
  }
}
