import { ProductGroup } from '../entities/product-group.entity';
import { ProductGroupDto } from '../dto/product-group.dto';

export class ProductGroupMapper {
  static toResponse(entity: ProductGroup): ProductGroupDto {
    return {
      id: entity.id,
      name: entity.name,
      description: entity.description ?? undefined,
      imageUrl: entity.imageUrl ? entity.imageUrl.toString('base64') : undefined,
    };
  }
}
