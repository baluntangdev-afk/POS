import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateRefundDto } from '../dto/create-refund.dto';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';

@Injectable()
export class RefundValidationService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {}

  async validateSalesOrderExists(salesOrderId: string): Promise<SalesOrder> {
    const salesOrder = await this.salesOrderRepository.findOne({
      where: { id: salesOrderId },
    });

    if (!salesOrder) {
      throw new NotFoundException('Original sales order not found');
    }

    return salesOrder;
  }

  async validateRefundItems(
    refundItems: CreateRefundDto['refundItems'],
    originalSalesOrderId: string,
  ): Promise<SalesOrderItem[]> {
    const salesOrderItemIds = refundItems.map((item) => item.salesOrderItemId);

    const salesOrderItems = await this.salesOrderItemRepository.find({
      where: salesOrderItemIds.map((id) => ({
        id,
        salesOrder: { id: originalSalesOrderId },
      })),
      relations: ['refundItems'],
    });

    if (salesOrderItems.length !== salesOrderItemIds.length) {
      throw new BadRequestException(
        'One or more sales order items not found or do not belong to the specified sales order',
      );
    }

    for (const refundItem of refundItems) {
      const originalItem = salesOrderItems.find((item) => item.id === refundItem.salesOrderItemId);

      const totalRefundedQuantity = originalItem!.refundItems.reduce(
        (sum, refundedItem) => sum + refundedItem.quantity,
        0,
      );

      const originalQuantity = parseFloat(originalItem!.qty);
      const availableQuantity = originalQuantity - totalRefundedQuantity;

      if (refundItem.quantity > availableQuantity) {
        throw new BadRequestException(
          `Refund quantity for item ${refundItem.salesOrderItemId} exceeds available quantity. Available: ${availableQuantity}, Requested: ${refundItem.quantity}`,
        );
      }
    }

    return salesOrderItems;
  }
}
