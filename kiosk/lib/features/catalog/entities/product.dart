import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'product_variant.dart';

part 'product.mapper.dart';

@MappableClass()
class Product with ProductMappable {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.variants = const IList.empty(),
  });

  factory Product.draft() => Product(id: 0, name: '', description: '', image: Uint8List(0));

  final int id;
  final String name;
  final String description;
  final Uint8List image;
  final IList<ProductVariant> variants;
}
