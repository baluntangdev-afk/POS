import 'package:dart_mappable/dart_mappable.dart';

part 'product_variant_dto.mapper.dart';

@MappableClass()
class ProductVariantDto with ProductVariantDtoMappable {
  const ProductVariantDto({
    required this.id,
    required this.productId,
    required this.name,
    required this.isDefault,
  });

  final int id;
  final int productId;
  final String name;
  final bool isDefault;

  static const fromJson = ProductVariantDtoMapper.fromJson;
}
