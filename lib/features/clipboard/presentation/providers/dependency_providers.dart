import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/clipboard_datasource.dart';
import '../../data/repositories/clipboard_repository_impl.dart';
import '../../domain/repositories/clipboard_repository.dart';

// Data Sources
final clipboardDataSourceProvider = Provider<ClipboardDataSource>((ref) {
  return ClipboardDataSource();
});

// Repositories
final clipboardRepositoryProvider = Provider<ClipboardRepository>((ref) {
  final dataSource = ref.watch(clipboardDataSourceProvider);
  return ClipboardRepositoryImpl(dataSource);
});
