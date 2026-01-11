import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/generate_pdf_usecase.dart';
import 'dependency_providers.dart';

// Use Cases
final generatePdfUseCaseProvider = Provider<GeneratePdfUseCase>((ref) {
  final repository = ref.watch(pdfRepositoryProvider);
  return GeneratePdfUseCase(repository);
});
