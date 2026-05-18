import { User } from '../../users/entities/user.entity';
import { DECIMAL_PLACES } from '../../utils/calculation.helper';
import { EntityHelper } from '../../utils/entity.helper';
import { ApplyDiscountItemDiscountDto } from '../dto/add-discount/apply-discount-item-discount.dto';
import { SalesOrderDiscount } from '../entities/sales-order-discount.entity';
import { SalesOrder } from '../entities/sales-order.entity';
import { Discount } from '../../discounts/entities/discount.entity';

export class SalesOrderDiscountMapper {
  static toEntity(
    soId: string,
    dto: ApplyDiscountItemDiscountDto,
    causer: User,
  ): SalesOrderDiscount {
    const salesOrderDiscount = new SalesOrderDiscount();

    salesOrderDiscount.salesOrder = EntityHelper.toIdEntity<SalesOrder>(soId);
    salesOrderDiscount.discount = EntityHelper.toIdEntity<Discount>(dto.id);
    salesOrderDiscount.appliedAmount = dto.value.toFixed(DECIMAL_PLACES);
    salesOrderDiscount.createdBy = causer;
    salesOrderDiscount.updatedBy = causer;

    return salesOrderDiscount;
  }

  /**
   * Creates a sales order discount with the given applied amount (e.g. item discount × qty per line).
   */
  static toEntityWithAppliedAmount(
    soId: string,
    discount: Discount,
    appliedAmount: string,
    causer: User,
  ): SalesOrderDiscount {
    const salesOrderDiscount = new SalesOrderDiscount();

    salesOrderDiscount.salesOrder = EntityHelper.toIdEntity<SalesOrder>(soId);
    salesOrderDiscount.discount = discount;
    salesOrderDiscount.appliedAmount = appliedAmount;
    salesOrderDiscount.createdBy = causer;
    salesOrderDiscount.updatedBy = causer;

    return salesOrderDiscount;
  }
}
