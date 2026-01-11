import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/load_ui_image_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import '../../domain/usecases/process_image_usecase.dart';
import 'dependency_providers.dart';

// Use Cases
final pickImageUseCaseProvider = Provider<PickImageUseCase>((ref) {
  final repository = ref.watch(imageRepositoryProvider);
  return PickImageUseCase(repository);
});

final loadUiImageUseCaseProvider = Provider<LoadUiImageUseCase>((ref) {
  final repository = ref.watch(imageRepositoryProvider);
  return LoadUiImageUseCase(repository);
});

final processImageUseCaseProvider = Provider<ProcessImageUseCase>((ref) {
  final repository = ref.watch(textRecognitionRepositoryProvider);
  return ProcessImageUseCase(repository);
});
