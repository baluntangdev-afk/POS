import { Injectable } from '@nestjs/common';
import { SalesOrderDiscountPersistenceService } from './sales-order-discount-persistence.service';
import { ApplyDiscountDto } from '../dto/add-discount/apply-discount.dto';
import { User } from '../../users/entities/user.entity';
import { SalesOrderItemBuildService } from './sales-order-item-build.service';
import { SalesOrderItemsPersistenceService } from './sales-order-items-persistence.service';
import { CreateSalesOrderMapper } from '../mapper/create-sales-order.mapper';
import { SalesOrderCalculationService } from './sales-order-calculation.service';
import { SalesOrder } from '../entities/sales-order.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrdersService } from '../sales-orders.service';

@Injectable()
export class AddDiscountToItemService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    private readonly salesOrdersService: SalesOrdersService,
    private readonly applyDiscountPersistence: SalesOrderDiscountPersistenceService,
    private readonly itemBuild: SalesOrderItemBuildService,
    private readonly itemsPersistence: SalesOrderItemsPersistenceService,
    private readonly calculation: SalesOrderCalculationService,
  ) {}

  async execute(soId: string, dto: ApplyDiscountDto, causer: User): Promise<any> {
    const salesOrder = await this.salesOrdersService.findOneWithoutItems(soId);
    const createDto = CreateSalesOrderMapper.toDto(salesOrder);

    const [currentSavedItems, soItemWithDiscounts] = await Promise.all([
      this.itemsPersistence.findSalesOrderItemsBySoId(soId),
      this.itemBuild.applyDiscountsToSalesOrderItems(dto.salesOrderItems, causer),
    ]);

    await this.calculation.applyOrderTotalsToDto(createDto, currentSavedItems, {
      soId,
      additionalSalesOrderDiscounts: soItemWithDiscounts.salesOrderDiscounts,
    });

    const persistedSalesOrder = CreateSalesOrderMapper.toEntity(createDto);

    const savedSoId = await this.salesOrderRepository.manager.transaction(
      async (transactionalEntityManager) => {
        const savedSo = await transactionalEntityManager.save(persistedSalesOrder);

        await this.itemsPersistence.saveSalesOrderItemsWithChild(
          soId,
          soItemWithDiscounts.salesOrderItems,
          transactionalEntityManager,
        );

        await this.applyDiscountPersistence.saveSalesOrderDiscounts(
          soItemWithDiscounts.salesOrderDiscounts,
          transactionalEntityManager,
        );

        return savedSo.id;
      },
    );

    return savedSoId;
  }
}
