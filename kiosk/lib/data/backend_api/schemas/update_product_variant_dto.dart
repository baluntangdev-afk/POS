import 'package:dart_mappable/dart_mappable.dart';

part 'update_product_variant_dto.mapper.dart';

@MappableClass(ignoreNull: true)
class UpdateProductVariantDto with UpdateProductVariantDtoMappable {
  const UpdateProductVariantDto({this.productId, this.name, this.isDefault});

  final int? productId;
  final String? name;
  final bool? isDefault;

  static const fromJson = UpdateProductVariantDtoMapper.fromJson;
}
