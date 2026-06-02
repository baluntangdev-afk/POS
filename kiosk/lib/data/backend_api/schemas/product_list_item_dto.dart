import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';

import '../mappers/image_url_mapper.dart';

part 'product_list_item_dto.mapper.dart';

@MappableClass(includeCustomMappers: [ImageUrlMapper()])
class ProductListItemDto with ProductListItemDtoMappable {
  const ProductListItemDto({required this.id, required this.name, required this.price, this.imageUrl, required this.categoryName});

  final int id;
  final String name;
  final String price;
  final Uint8List? imageUrl;
  final String categoryName;

  static const fromJson = ProductListItemDtoMapper.fromJson;
}
