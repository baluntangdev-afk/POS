import 'dart:typed_data';

import 'package:mime/mime.dart';

extension FileSniffer on Uint8List {
  String get mimeType {
    return lookupMimeType('', headerBytes: this) ?? 'application/octet-stream';
  }

  String get fileExtension {
    final mime = mimeType;
    if (mime == 'application/octet-stream') return 'bin';
    return mime.split('/').last.split('+').first;
  }
}
