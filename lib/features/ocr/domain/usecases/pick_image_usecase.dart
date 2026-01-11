import 'package:image_picker/image_picker.dart';
import '../entities/image_entity.dart';
import '../repositories/image_repository.dart';

/// Use case for picking an image from camera or gallery
class PickImageUseCase {
  final ImageRepository _imageRepository;

  PickImageUseCase(this._imageRepository);

  Future<ImageEntity?> call(ImageSource source) async {
    return await _imageRepository.pickImage(source);
  }
}
