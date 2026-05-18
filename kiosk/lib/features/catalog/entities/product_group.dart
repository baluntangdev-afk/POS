import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

part 'product_group.mapper.dart';

@MappableClass()
class ProductGroup with ProductGroupMappable {
  const ProductGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory ProductGroup.draft() =>
      ProductGroup(id: 0, name: '', description: '', image: Uint8List(0));

  final int id;
  final String name;
  final String description;
  final Uint8List image;
}
