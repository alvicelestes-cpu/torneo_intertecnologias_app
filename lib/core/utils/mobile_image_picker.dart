import 'dart:convert';
import 'dart:typed_data';

import 'mobile_image_picker_stub.dart'
    if (dart.library.html) 'mobile_image_picker_web.dart'
    if (dart.library.io) 'mobile_image_picker_io.dart';

class AppPickedImage {
  final Uint8List bytes;
  final String mimeType;
  final String name;

  const AppPickedImage({
    required this.bytes,
    required this.mimeType,
    required this.name,
  });

  String get dataUri {
    final b64 = base64Encode(bytes);
    return 'data:$mimeType;base64,$b64';
  }
}

class MobileImagePicker {
  MobileImagePicker._();

  /// Abre el explorador de archivos o selector de cámara/galería del dispositivo
  /// garantizando compatibilidad con navegadores móviles (Chrome/Safari en Android/iOS)
  /// y aplicaciones nativas.
  static Future<AppPickedImage?> pickImage() {
    return pickImagePlatform();
  }
}
