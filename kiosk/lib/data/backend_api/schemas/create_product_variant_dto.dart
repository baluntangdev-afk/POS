import 'package:dart_mappable/dart_mappable.dart';

part 'create_product_variant_dto.mapper.dart';

@MappableClass()
class CreateProductVariantDto with CreateProductVariantDtoMappable {
  const CreateProductVariantDto({
    required this.productId,
    required this.name,
    required this.isDefault,
  });

  final int productId;
  final String name;
  final bool isDefault;

  static const fromJson = CreateProductVariantDtoMapper.fromJson;
}
