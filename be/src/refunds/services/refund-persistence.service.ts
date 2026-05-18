import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { Refund } from '../entities/refund.entity';
import { RefundItem } from '../entities/refund-item.entity';
import { CreateRefundDto } from '../dto/create-refund.dto';

@Injectable()
export class RefundPersistenceService {
  constructor() {}

  async saveRefund(createRefundDto: CreateRefundDto, manager: EntityManager): Promise<Refund> {
    const refund = manager.create(Refund, {
      refundNumber: createRefundDto.refundNumber,
      originalSalesOrder: { id: createRefundDto.originalSalesOrderId },
      reason: createRefundDto.reason,
      totalRefundAmount: createRefundDto.totalRefundAmount.toString(),
      paymentMethod: createRefundDto.paymentMethod,
      transactionReference: createRefundDto.transactionReference,
      refundDate: createRefundDto.refundDate || new Date(),
      createdBy: createRefundDto.createdBy,
      updatedBy: createRefundDto.updatedBy,
    });

    return await manager.save(refund);
  }

  async saveRefundItems(
    refundId: number,
    refundItems: CreateRefundDto['refundItems'],
    manager: EntityManager,
  ): Promise<RefundItem[]> {
    const refundItemsWithRefund = refundItems.map((refundItemDto) =>
      manager.create(RefundItem, {
        refund: { id: refundId },
        salesOrderItem: { id: refundItemDto.salesOrderItemId },
        quantity: refundItemDto.quantity,
        refundAmount: refundItemDto.refundAmount.toString(),
        restockInventory: refundItemDto.restockInventory || false,
      }),
    );

    return manager.save(refundItemsWithRefund);
  }
}
