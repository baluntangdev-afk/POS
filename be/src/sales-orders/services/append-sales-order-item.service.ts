import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateSalesOrderDto } from '../dto/create-sales-order/create-sales-order.dto';
import { User } from '../../users/entities/user.entity';
import { CreateSalesOrderMapper } from '../mapper/create-sales-order.mapper';
import { SalesOrder } from '../entities/sales-order.entity';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SalesOrderEvents } from '../events';
import { OrderAppendEvent } from '../events/order-append.event';
import { OrderCreatedEventMapper } from '../mapper/order-created-event.mapper';
import { SalesOrderCalculationService } from './sales-order-calculation.service';
import { SalesOrderItemBuildService } from './sales-order-item-build.service';
import { SalesOrderInventoryValidationService } from './sales-order-inventory-validation.service';
import { SalesOrderItemsPersistenceService } from './sales-order-items-persistence.service';

@Injectable()
export class AppendSalesOrderItemService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    private readonly itemBuild: SalesOrderItemBuildService,
    private readonly inventoryValidation: SalesOrderInventoryValidationService,
    private readonly itemsPersistence: SalesOrderItemsPersistenceService,
    private readonly calculation: SalesOrderCalculationService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(dto: CreateSalesOrderDto, causer: User): Promise<string> {
    dto.createdBy = causer;
    dto.updatedBy = causer;

    const [currentSavedItems, { salesOrderItems }] = await Promise.all([
      this.itemsPersistence.findSalesOrderItemsBySoId(dto.id!),
      this.itemBuild.generateSalesOrderItems(dto.products, causer, dto.id),
    ]);

    await this.inventoryValidation.validateInventoryAvailability(salesOrderItems);
    await this.calculation.applyOrderTotalsToDto(dto, [...currentSavedItems, ...salesOrderItems], {
      soId: dto.id,
    });

    const salesOrder = CreateSalesOrderMapper.toEntity(dto);

    const { savedSo, savedSoItems } = await this.salesOrderRepository.manager.transaction(
      async (transactionalEntityManager) => {
        const savedSo = await transactionalEntityManager.save(salesOrder);
        const savedSoItems = await this.itemsPersistence.saveSalesOrderItems(
          savedSo.id,
          salesOrderItems,
          transactionalEntityManager,
        );
        return { savedSo, savedSoItems };
      },
    );

    this.eventEmitter.emit(
      SalesOrderEvents.ORDER_APPEND,
      new OrderAppendEvent(savedSo.id, {
        items: OrderCreatedEventMapper.toEventItems(savedSoItems),
        causer,
      }),
    );

    return savedSo.id;
  }
}
