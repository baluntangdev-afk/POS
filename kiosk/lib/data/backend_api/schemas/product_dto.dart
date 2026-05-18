import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

import '../mappers/image_url_mapper.dart';

part 'product_dto.mapper.dart';

@MappableClass(includeCustomMappers: [ImageUrlMapper()])
class ProductDto with ProductDtoMappable {
  const ProductDto({required this.id, required this.name, this.description, this.imageUrl});

  final int id;
  final String name;
  final String? description;
  final Uint8List? imageUrl;

  static const fromJson = ProductDtoMapper.fromJson;
}
