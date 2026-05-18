import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { User } from '../../users/entities/user.entity';
import { EntityHelper } from '../../utils/entity.helper';
import { CreateInventoryCountDto } from '../dto/create-inventory-count/create-inventory-count.dto';
import { InventoryCountType } from '../entities/inventory-count-type.entity';
import { InventoryCount } from '../entities/inventory-count.entity';

export class CreateInventoryCountMapper {
  static toEntity(dto: CreateInventoryCountDto): InventoryCount {
    const inventoryCount = new InventoryCount();

    inventoryCount.salesOrder = EntityHelper.toIdEntity<SalesOrder>(dto.salesOrderId);
    inventoryCount.type = EntityHelper.toIdEntity<InventoryCountType>(dto.typeId);
    inventoryCount.createdBy = EntityHelper.toIdEntity<User>(dto.createdById);
    inventoryCount.updatedBy = EntityHelper.toIdEntity<User>(dto.createdById);

    return inventoryCount;
  }
}
