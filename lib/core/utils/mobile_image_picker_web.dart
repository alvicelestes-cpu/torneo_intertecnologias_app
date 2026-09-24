// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'mobile_image_picker.dart';

Future<AppPickedImage?> pickImagePlatform() {
  try {
    final completer = Completer<AppPickedImage?>();

    final uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;

    uploadInput.style.display = 'none';
    html.document.body?.children.add(uploadInput);

    void cleanup() {
      try {
        uploadInput.remove();
      } catch (_) {}
    }

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((_) {
        cleanup();
        try {
          final result = reader.result;
          Uint8List? bytes;
          if (result is Uint8List) {
            bytes = result;
          } else if (result is ByteBuffer) {
            bytes = result.asUint8List();
          } else if (result is List<int>) {
            bytes = Uint8List.fromList(result);
          }

          if (bytes != null && bytes.isNotEmpty) {
            final mimeType = file.type.isNotEmpty ? file.type : 'image/jpeg';
            if (!completer.isCompleted) {
              completer.complete(AppPickedImage(
                bytes: bytes,
                mimeType: mimeType,
                name: file.name,
              ));
            }
          } else {
            if (!completer.isCompleted) completer.complete(null);
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      });

      reader.onError.listen((_) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
      });
    });

    try {
      uploadInput.addEventListener('cancel', (_) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
      });
    } catch (_) {}

    // Invocación directa y síncrona en el ciclo táctil del usuario para móviles
    uploadInput.click();

    return completer.future;
  } catch (_) {
    return _fallbackImagePicker();
  }
}

Future<AppPickedImage?> _fallbackImagePicker() async {
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
