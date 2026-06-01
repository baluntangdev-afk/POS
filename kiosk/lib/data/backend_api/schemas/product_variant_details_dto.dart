import 'package:dart_mappable/dart_mappable.dart';

part 'product_variant_details_dto.mapper.dart';

@MappableClass()
class ProductVariantDetailsDto with ProductVariantDetailsDtoMappable {
  const ProductVariantDetailsDto({
    required this.id,
    required this.name,
    required this.displayPrice,
    required this.isDefault,
  });

  final int id;
  final String name;
  final String displayPrice;
  final bool isDefault;

  static const fromJson = ProductVariantDetailsDtoMapper.fromJson;
}
