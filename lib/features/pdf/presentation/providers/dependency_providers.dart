import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/pdf_datasource.dart';
import '../../data/repositories/pdf_repository_impl.dart';
import '../../domain/repositories/pdf_repository.dart';

// Data Sources
final pdfDataSourceProvider = Provider<PdfDataSource>((ref) {
  return PdfDataSource();
});

// Repositories
final pdfRepositoryProvider = Provider<PdfRepository>((ref) {
  final dataSource = ref.watch(pdfDataSourceProvider);
  return PdfRepositoryImpl(dataSource);
});
