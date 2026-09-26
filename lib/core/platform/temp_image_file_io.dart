import 'dart:io';
import 'dart:typed_data';

Future<String?> writeTempImageFile(
  Uint8List bytes, {
  String extension = 'png',
}) async {
  final path =
      '${Directory.systemTemp.path}/wwngo_avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
