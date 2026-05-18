import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { SalesOrder } from '../entities/sales-order.entity';
import { CreateSalesOrderDto } from '../dto/create-sales-order/create-sales-order.dto';
import { User } from '../../users/entities/user.entity';
import dayjs from 'dayjs';
import { SalesOrderStatus } from '../sales-orders.enum';
import { CreateSalesOrderMapper } from '../mapper/create-sales-order.mapper';
import { getKioskNo } from '../../utils/file.helper';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrderCreatedEvent } from '../events/order-created.event';
import { SalesOrderEvents } from '../events';
import { OrderCreatedEventMapper } from '../mapper/order-created-event.mapper';
import { SalesOrderCalculationService } from './sales-order-calculation.service';
import { SalesOrderItemBuildService } from './sales-order-item-build.service';
import { SalesOrderInventoryValidationService } from './sales-order-inventory-validation.service';
import { SalesOrderItemsPersistenceService } from './sales-order-items-persistence.service';
import { SalesOrderDiscountPersistenceService } from './sales-order-discount-persistence.service';

@Injectable()
export class CreateSalesOrderService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    private readonly itemBuild: SalesOrderItemBuildService,
    private readonly inventoryValidation: SalesOrderInventoryValidationService,
    private readonly itemsPersistence: SalesOrderItemsPersistenceService,
    private readonly calculation: SalesOrderCalculationService,
    private readonly discountPersistence: SalesOrderDiscountPersistenceService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async execute(dto: CreateSalesOrderDto, causer: User) {
    dto.soNumber = await this.generateSoNumber();
    dto.soDate = dayjs().toDate();
    dto.status = SalesOrderStatus.PENDING;
    dto.createdBy = causer;
    dto.updatedBy = causer;

    const result = await this.itemBuild.generateSalesOrderItems(dto.products, causer);
    const salesOrderItems = result.salesOrderItems;
    const salesOrderDiscounts = result.salesOrderDiscounts;

    await this.inventoryValidation.validateInventoryAvailability(salesOrderItems);
    await this.calculation.applyOrderTotalsToDto(dto, salesOrderItems, {
      additionalSalesOrderDiscounts: salesOrderDiscounts,
    });

    const salesOrder = CreateSalesOrderMapper.toEntity(dto);

    const { savedSo, savedSoItems } = await this.salesOrderRepository.manager.transaction(
      async (transactionalEntityManager) => {
        const savedSo = await this.saveSalesOrder(salesOrder, transactionalEntityManager);
        const savedSoItems = await this.itemsPersistence.saveSalesOrderItems(
          savedSo.id,
          salesOrderItems,
          transactionalEntityManager,
        );

        if (salesOrderDiscounts.length > 0) {
          salesOrderDiscounts.forEach((discount) => {
            discount.salesOrder = savedSo;
          });
          await this.discountPersistence.saveSalesOrderDiscounts(
            salesOrderDiscounts,
            transactionalEntityManager,
          );
        }

        return { savedSo, savedSoItems };
      },
    );

    this.eventEmitter.emit(
      SalesOrderEvents.ORDER_CREATED,
      new OrderCreatedEvent(savedSo.id, {
        items: OrderCreatedEventMapper.toEventItems(savedSoItems),
        causer,
      }),
    );

    return savedSo.id;
  }

  private async saveSalesOrder(salesOrder: SalesOrder, t: EntityManager) {
    return t.save(salesOrder);
  }

  private async generateSoNumber(): Promise<string> {
    const currentYear = dayjs().format('YYYY');
    const kioskNo = getKioskNo();
    const prefix = `SO-${kioskNo.padStart(3, '0')}-${currentYear}`;

    const lastSoNumber = await this.salesOrderRepository
      .createQueryBuilder('salesOrder')
      .select('salesOrder.soNumber')
      .where('salesOrder.soNumber LIKE :prefix', { prefix: `${prefix}%` })
      .orderBy('salesOrder.soNumber', 'DESC')
      .withDeleted()
      .getOne();

    if (!lastSoNumber) {
      return `${prefix}-0001`;
    }

    const lastFour = lastSoNumber.soNumber.slice(-4);
    const lastSoNumberInt = parseInt(lastFour, 10);
    const nextSoNumberInt = lastSoNumberInt + 1;
    return `${prefix}-${nextSoNumberInt.toString().padStart(4, '0')}`;
  }
}
