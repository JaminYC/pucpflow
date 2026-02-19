import 'dart:typed_data';

import 'file_bytes_loader_stub.dart'
    if (dart.library.io) 'file_bytes_loader_io.dart'
    if (dart.library.html) 'file_bytes_loader_web.dart';

Future<Uint8List?> loadFileBytes(String path) => loadFileBytesImpl(path);
