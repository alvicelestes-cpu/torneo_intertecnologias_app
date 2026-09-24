import 'package:image_picker/image_picker.dart';

import 'mobile_image_picker.dart';

Future<AppPickedImage?> pickImagePlatform() async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';
      return AppPickedImage(
        bytes: bytes,
        mimeType: mimeType,
        name: picked.name,
      );
    }
  } catch (_) {}
  return null;
}
