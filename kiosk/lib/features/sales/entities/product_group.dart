import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

part 'product_group.mapper.dart';

@MappableClass()
class ProductGroup with ProductGroupMappable {
  const ProductGroup({required this.id, required this.name, required this.image});

  final int id;
  final String name;
  final Uint8List image;
}
