import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> loadFileBytesImpl(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
