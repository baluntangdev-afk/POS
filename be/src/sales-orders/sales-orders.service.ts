import { Injectable, NotFoundException } from '@nestjs/common';
import { User } from '../users/entities/user.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { SalesOrder } from './entities/sales-order.entity';
import { Refund } from '../refunds/entities/refund.entity';
import { In, Repository, FindOptionsWhere, Between } from 'typeorm';
import { SalesOrderStatus } from './sales-orders.enum';
import { CreateSalesOrderService } from './services/create-sales-order.service';
import { CreateSalesOrderDto } from './dto/create-sales-order/create-sales-order.dto';
import { SalesOrderWithItemsMapper } from './mapper/sales-order-with-items.mapper';
import { SalesOrderWithItemsResponseDto } from './dto/sales-order-with-items-response.dto';
import { AppendSalesOrderItemService } from './services/append-sales-order-item.service';
import { ProductDetailsDto } from '../products/dto/product-details/product-details.dto';
import { SalesOrderItem } from './entities/sales-order-item.entity';
import { ProductsService } from '../products/products.service';
import { SalesOrderQueryDto } from './dto/sales-order-query.dto';
import { PaginatedResult, parseSort } from '../utils/pagination';
import dayjs from 'dayjs';

@Injectable()
export class SalesOrdersService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(Refund)
    private readonly refundRepository: Repository<Refund>,
    private readonly productsService: ProductsService,
    private readonly createSalesOrderService: CreateSalesOrderService,
    private readonly appendSalesOrderItemService: AppendSalesOrderItemService,
  ) {}

  async findAll(
    query: SalesOrderQueryDto,
    currentUser: User,
  ): Promise<PaginatedResult<SalesOrderWithItemsResponseDto>> {
    const { page, limit, sort, soNumber, soDate, soType, createdBy, status } = query;
    const skip = (page - 1) * limit;

    const SALES_ORDER_SORTABLE_FIELDS: (keyof SalesOrder)[] = [
      'id',
      'soNumber',
      'soDate',
      'soType',
      'status',
      'totalAmount',
      'finalTotalAmount',
    ];
    const order = parseSort<SalesOrder>(sort, {
      allowedFields: SALES_ORDER_SORTABLE_FIELDS,
      defaultOrder: { id: 'DESC' },
    });

    const where: FindOptionsWhere<SalesOrder> = {};

    if (soNumber) {
      where.soNumber = soNumber;
    }

    if (soDate) {
      const startDate = dayjs(soDate).startOf('day').toDate();
      const endDate = dayjs(soDate).endOf('day').toDate();
      where.soDate = Between(startDate, endDate);
    }

    if (soType) {
      where.soType = soType;
    }

    if (!currentUser.systemAdmin) {
      where.createdBy = { id: currentUser.id };
    } else if (createdBy) {
      where.createdBy = { id: createdBy };
    }

    if (status) {
      where.status = status;
    }

    const [salesOrders, total] = await this.salesOrderRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      select: {
        id: true,
        soNumber: true,
        soDate: true,
        soType: true,
        status: true,
        discountRate: true,
        discountAmount: true,
        taxRate: true,
        taxAmount: true,
        totalAmount: true,
        finalTotalAmount: true,
        voidReason: true,
        voidedAt: true,
        createdBy: { id: true },
        salesOrderItems: {
          id: true,
          itemSequence: true,
          addOn: true,
          description: true,
          qty: true,
          unitPrice: true,
          itemDiscountRate: true,
          itemDiscountedPrice: true,
          vatExclusiveAmount: true,
          vatAmount: true,
          itemSubtotal: true,
          itemTotalAmount: true,
          status: true,
          productVariant: { id: true },
          recipe: { id: true },
          uom: { id: true },
          recipeItem: { id: true },
        },
      },
      relations: {
        createdBy: true,
        salesOrderItems: {
          productVariant: true,
          recipe: true,
          uom: true,
          recipeItem: true,
        },
      },
    });

    const refundAmounts = await this.getRefundAmountsBySoIds(salesOrders.map((so) => so.id));
    const data = salesOrders.map((so) =>
      SalesOrderWithItemsMapper.toResponse(so, refundAmounts.get(so.id) ?? 0),
    );

    return { data, total, page, limit };
  }

  findOne(id: string): Promise<SalesOrderWithItemsResponseDto> {
    return this.findOneWithItems(id);
  }

  async findOneWithoutItems(id: string) {
    const salesOrder = await this.salesOrderRepository.findOne({
      where: { id },
    });

    if (!salesOrder) {
      throw new NotFoundException('Sales order not found');
    }

    return salesOrder;
  }

  async findOneWithItems(id: string): Promise<SalesOrderWithItemsResponseDto> {
    const salesOrder = await this.salesOrderRepository.findOne({
      select: {
        id: true,
        soNumber: true,
        soDate: true,
        soType: true,
        status: true,
        discountRate: true,
        discountAmount: true,
        taxRate: true,
        taxAmount: true,
        totalAmount: true,
        finalTotalAmount: true,
        voidReason: true,
        voidedAt: true,
        createdBy: { id: true },
        salesOrderItems: {
          id: true,
          itemSequence: true,
          addOn: true,
          description: true,
          qty: true,
          unitPrice: true,
          itemDiscountRate: true,
          itemDiscountedPrice: true,
          vatExclusiveAmount: true,
          vatAmount: true,
          itemSubtotal: true,
          itemTotalAmount: true,
          status: true,
          productVariant: { id: true },
          recipe: { id: true },
          uom: { id: true },
          recipeItem: { id: true },
        },
      },
      where: { id },
      relations: {
        createdBy: true,
        salesOrderItems: {
          productVariant: true,
          recipe: true,
          uom: true,
          recipeItem: true,
        },
      },
      order: { salesOrderItems: { itemSequence: 'ASC' } },
    });

    if (!salesOrder) {
      throw new NotFoundException('Sales order not found');
    }

    const refundAmounts = await this.getRefundAmountsBySoIds([id]);
    return SalesOrderWithItemsMapper.toResponse(salesOrder, refundAmounts.get(id) ?? 0);
  }

  async findOneItem(id: string, itemId: string): Promise<ProductDetailsDto> {
    const salesOrderItem = await this.salesOrderItemRepository.findOne({
      select: {
        id: true,
        itemSequence: true,
        addOn: true,
        productVariant: { id: true, product: { id: true } },
      },
      where: { id: itemId, salesOrder: { id } },
      relations: { productVariant: { product: true } },
    });

    if (!salesOrderItem) {
      throw new NotFoundException('Sales order item not found');
    }

    // get sales order item add on
    const salesOrderItemAddon = await this.salesOrderItemRepository.find({
      select: { id: true, description: true },
      where: { itemSequence: salesOrderItem.itemSequence!, addOn: true, salesOrder: { id } },
    });
    const addOnNames = new Set(salesOrderItemAddon.map((addon) => addon.description));

    if (!salesOrderItem.productVariant) {
      throw new NotFoundException('Product variant not found for this sales order item');
    }

    const productDetails = await this.productsService.findOne(
      salesOrderItem.productVariant.product.id,
    );

    productDetails.modifierGroups.forEach((modifierGroup) => {
      modifierGroup.options.forEach((option) => {
        option.isSelected = addOnNames.has(option.name);
      });
    });

    return productDetails;
  }

  async findCurrentWithItems(userId: number): Promise<SalesOrderWithItemsResponseDto> {
    const so = await this.findCurrentByUser(userId);

    if (!so) {
      throw new NotFoundException('Current sales order not found');
    }

    return this.findOneWithItems(so.id);
  }

  findCurrentByUser(userId: number) {
    return this.salesOrderRepository.findOne({
      select: { id: true },
      where: {
        createdBy: { id: userId },
        status: In([SalesOrderStatus.PENDING, SalesOrderStatus.PREPARING]),
      },
    });
  }

  private async getRefundAmountsBySoIds(soIds: string[]): Promise<Map<string, number>> {
    if (soIds.length === 0) return new Map();
    const rows = await this.refundRepository
      .createQueryBuilder('r')
      .innerJoin('r.originalSalesOrder', 'so')
      .select('so.id', 'soId')
      .addSelect('SUM(r.totalRefundAmount)', 'total')
      .where('so.id IN (:...ids)', { ids: soIds })
      .groupBy('so.id')
      .getRawMany<{ soId: string; total: string }>();
    return new Map(rows.map((r) => [r.soId, parseFloat(r.total ?? '0')]));
  }

  async upsert(dto: CreateSalesOrderDto, causer: User): Promise<SalesOrderWithItemsMapper> {
    const so = await this.findCurrentByUser(causer.id);

    if (so) {
      dto.id = so.id;
      await this.appendSalesOrderItemService.execute(dto, causer);
      return this.findOneWithItems(so.id);
    } else {
      const savedSoId = await this.createSalesOrderService.execute(dto, causer);
      return this.findOneWithItems(savedSoId);
    }
  }
}
