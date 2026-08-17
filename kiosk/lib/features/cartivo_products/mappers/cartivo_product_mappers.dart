import '../../../data/backend_api/schemas/cartivo_product_dto.dart';
import '../entities/cartivo_product.dart';

extension DTOMapper on CartivoProductDto {
  CartivoProduct get toEntity => CartivoProduct(
    id: id,
    name: name,
    price: price / 100,
    currency: currency,
    createdAt: createdAt,
  );
}
