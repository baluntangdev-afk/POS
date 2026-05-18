import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

import '../mappers/image_url_mapper.dart';
import 'product_variant_details_dto.dart';

part 'product_details_dto.mapper.dart';

@MappableClass(includeCustomMappers: [ImageUrlMapper()])
class ProductDetailsDto with ProductDetailsDtoMappable {
  const ProductDetailsDto({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.currencySign,
    required this.displayPrice,
    required this.variants,
  });

  final int id;
  final String name;
  final String description;
  final Uint8List imageUrl;
  final String currencySign;
  final String displayPrice;
  final List<ProductVariantDetailsDto> variants;

  static const fromJson = ProductDetailsDtoMapper.fromJson;
}
