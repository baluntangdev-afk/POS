import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'modifier_group.dart';

part 'product.mapper.dart';

@MappableClass()
class Product with ProductMappable {
  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.modifierGroups,
    this.defaultVariantId = 0,
  });

  final int id;
  final String name;
  final Uint8List image;
  final Decimal price;
  final IList<ModifierGroup> modifierGroups;
  final int defaultVariantId;
}
