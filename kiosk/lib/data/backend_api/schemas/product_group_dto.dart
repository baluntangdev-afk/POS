import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

import '../mappers/image_url_mapper.dart';

part 'product_group_dto.mapper.dart';

@MappableClass(includeCustomMappers: [ImageUrlMapper()])
class ProductGroupDto with ProductGroupDtoMappable {
  const ProductGroupDto({required this.id, required this.name, this.description, this.imageUrl});

  final int id;
  final String name;
  final String? description;
  final Uint8List? imageUrl;

  static const fromJson = ProductGroupDtoMapper.fromJson;
}
