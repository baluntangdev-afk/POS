import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'modifier_group.dart';

part 'product_variant.mapper.dart';

@MappableClass()
class ProductVariant with ProductVariantMappable {
  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
    required this.modifierGroups,
  });

  final int id;
  final String name;
  final Decimal price;
  final bool isDefault;
  final IList<ModifierGroup> modifierGroups;
}
