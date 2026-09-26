import 'dart:typed_data';

import 'temp_image_file_io.dart'
    if (dart.library.html) 'temp_image_file_web.dart' as impl;

/// Writes image bytes to a temporary file path when the platform supports it.
/// Returns null on web (upload via bytes instead).
Future<String?> writeTempImageFile(
  Uint8List bytes, {
  String extension = 'png',
}) {
  return impl.writeTempImageFile(bytes, extension: extension);
}
