import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

class ImageUrlMapper extends SimpleMapper<Uint8List> {
  const ImageUrlMapper();

  @override
  Uint8List decode(Object value) {
    if (value is String) {
      final sanitized = value.contains(',') ? value.split(',').last : value;
      return base64Decode(sanitized);
    } else if (value is Map<String, dynamic> && value['data'] is List) {
      final dataList = List<int>.from(value['data'] as List);
      return Uint8List.fromList(dataList);
    }
    throw MapperException.unexpectedType(value.runtimeType, 'String (Base64) or Buffer Map');
  }

  @override
  String encode(Uint8List self) {
    return base64Encode(self);
  }
}
