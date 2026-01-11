import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/copy_text_usecase.dart';
import 'dependency_providers.dart';

// Use Cases
final copyTextUseCaseProvider = Provider<CopyTextUseCase>((ref) {
  final repository = ref.watch(clipboardRepositoryProvider);
  return CopyTextUseCase(repository);
});
