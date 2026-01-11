import '../../domain/repositories/clipboard_repository.dart';
import '../datasources/clipboard_datasource.dart';

/// Implementation of ClipboardRepository
class ClipboardRepositoryImpl implements ClipboardRepository {
  final ClipboardDataSource _dataSource;

  ClipboardRepositoryImpl(this._dataSource);

  @override
  Future<void> copyText(String text) async {
    try {
      await _dataSource.copyText(text);
    } catch (e) {
      throw Exception('Failed to copy text: $e');
    }
  }
}
