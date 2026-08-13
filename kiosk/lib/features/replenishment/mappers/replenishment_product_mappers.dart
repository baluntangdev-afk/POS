import '../../../data/backend_api/schemas/replenishment_product_dto.dart';
import '../entities/replenishment_product.dart';

extension DTOMapper on ReplenishmentProductDto {
  ReplenishmentProduct get toEntity => ReplenishmentProduct(
    id: id,
    name: name,
    price: price / 100,
    currency: currency,
    createdAt: createdAt,
  );
}
