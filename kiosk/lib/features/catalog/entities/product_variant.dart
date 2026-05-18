import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

part 'product_variant.mapper.dart';

@MappableClass()
class ProductVariant with ProductVariantMappable {
  const ProductVariant({required this.id, required this.name, required this.isDefault, this.image});

  final int id;
  final String name;
  final bool isDefault;
  final Uint8List? image;
}
