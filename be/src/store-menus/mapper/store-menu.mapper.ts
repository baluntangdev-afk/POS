import { StoreMenu } from '../entities/store-menu.entity';
import { StoreMenuDto } from '../dto/store-menu.dto';

export class StoreMenuMapper {
  static toStoreMenuDto(entity: StoreMenu): StoreMenuDto {
    return {
      id: entity.id,
      name: entity.name,
      description: entity.description || undefined,
      status: entity.status,
    };
  }
}
