import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

part 'product_variant.mapper.dart';

@MappableClass()
class ProductVariant with ProductVariantMappable {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
  });

  final int id;
  final String name;
  final Decimal price;
  final bool isDefault;
}
