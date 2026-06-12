import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickBusinessCardImage({
    required ImageSource source,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 85,
      );
    } on PlatformException {
      if (source == ImageSource.gallery) {
        rethrow;
      }

      // Camera access can fail on the simulator or when permissions are denied.
      // Falling back to the gallery keeps the scan flow usable.
      return _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 85,
      );
    }
  }
}
