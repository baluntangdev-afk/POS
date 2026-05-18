import { Product } from '../entities/product.entity';
import { ProductDto } from '../dto/product.dto';

export class ProductMapper {
  static toProductDto(entity: Product): ProductDto {
    return {
      id: entity.id,
      groupId: entity.productGroup.id,
      name: entity.name,
      description: entity.description ?? undefined,
      imageUrl: entity.imageUrl ? entity.imageUrl.toString('base64') : undefined,
    };
  }
}
