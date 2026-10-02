import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_products_page_dto.mapper.dart';

/// One page of `GET /pos/merchants/{merchant_id}/products`.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class CartivoProductsPageDto with CartivoProductsPageDtoMappable {
  const CartivoProductsPageDto({
    required this.merchantId,
    required this.currency,
    required this.generatedAt,
    required this.data,
    required this.meta,
  });

  final String merchantId;
  final String currency;

  /// Cartivo's clock when it built this page. Use it (not the device clock) as
  /// the `updated_since` watermark for the next delta sync.
  final DateTime generatedAt;

  final List<CartivoProductDto> data;
  final CartivoPageMetaDto meta;

  static const fromJson = CartivoProductsPageDtoMapper.fromJson;
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class CartivoPageMetaDto with CartivoPageMetaDtoMappable {
  const CartivoPageMetaDto({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  final int page;
  final int limit;

  /// Number of products matching the request across **all** pages.
  final int total;

  final bool hasNext;

  static const fromJson = CartivoPageMetaDtoMapper.fromJson;
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class CartivoProductDto with CartivoProductDtoMappable {
  const CartivoProductDto({
    required this.productId,
    required this.name,
    required this.updatedAt,
    required this.variants,
    this.category,
    this.imageUrl,
  });

  final int productId;
  final String name;
  final String? category;
  final String? imageUrl;
  final DateTime updatedAt;
  final List<CartivoVariantDto> variants;

  static const fromJson = CartivoProductDtoMapper.fromJson;
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class CartivoVariantDto with CartivoVariantDtoMappable {
  const CartivoVariantDto({
    required this.variantId,
    required this.sku,
    required this.variantName,
    required this.price,
    required this.availableQuantity,
    required this.isAvailable,
    required this.updatedAt,
  });

  final int variantId;
  final String sku;
  final String variantName;
  final double price;
  final int availableQuantity;
  final bool isAvailable;
  final DateTime updatedAt;

  static const fromJson = CartivoVariantDtoMapper.fromJson;
}
