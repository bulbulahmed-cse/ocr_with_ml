import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/image_picker_datasource.dart';
import '../../data/datasources/mlkit_datasource.dart';
import '../../data/repositories/image_repository_impl.dart';
import '../../data/repositories/text_recognition_repository_impl.dart';
import '../../domain/repositories/image_repository.dart';
import '../../domain/repositories/text_recognition_repository.dart';

// Script selection provider
final recognitionScriptProvider =
    StateProvider<RecognitionScript>((ref) => RecognitionScript.latin);

// Data Sources
final imagePickerDataSourceProvider = Provider<ImagePickerDataSource>((ref) {
  return ImagePickerDataSource();
});

final mlKitDataSourceProvider = Provider<MlKitDataSource>((ref) {
  final script = ref.watch(recognitionScriptProvider);
  final dataSource = MlKitDataSource(script: script);
  ref.onDispose(() => dataSource.dispose());
  
  // Update script when it changes
  ref.listen(recognitionScriptProvider, (previous, next) {
    if (previous != next) {
      dataSource.setScript(next);
    }
  });
  
  return dataSource;
});

// Repositories
final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  final dataSource = ref.watch(imagePickerDataSourceProvider);
  return ImageRepositoryImpl(dataSource);
});

final textRecognitionRepositoryProvider =
    Provider<TextRecognitionRepository>((ref) {
  final dataSource = ref.watch(mlKitDataSourceProvider);
  return TextRecognitionRepositoryImpl(dataSource);
});
