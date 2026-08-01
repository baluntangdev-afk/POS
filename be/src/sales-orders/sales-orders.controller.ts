import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiResponse,
} from '@nestjs/swagger';
import { SalesOrdersService } from './sales-orders.service';
import { CreateSalesOrderDto } from './dto/create-sales-order/create-sales-order.dto';
import { SalesOrderWithItemsResponseDto } from './dto/sales-order-with-items-response.dto';
import { UpdateSalesOrderDto } from './dto/update-sales-order.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { SalesOrderWithItemsMapper } from './mapper/sales-order-with-items.mapper';
import { UpdateSalesOrderItemService } from './services/update-sales-order-item.service';
import { RemoveSalesOrderItemService } from './services/remove-sales-order-item.service';
import { ApplyDiscountDto } from './dto/add-discount/apply-discount.dto';
import { AddDiscountToItemService } from './services/add-discount-to-item.service';
import { ConfirmSalesOrderDto } from './dto/confirm-sales-order/confirm-sales-order.dto';
import { ConfirmSalesOrderService } from './services/confirm-sales-order.service';
import { SalesOrderQueryDto } from './dto/sales-order-query.dto';
import { VoidSalesOrderDto } from './dto/void-sales-order.dto';
import { VoidSalesOrderService } from './services/void-sales-order.service';
import { PaginatedResponse } from '../utils/pagination/dto';

@ApiTags('Sales Orders')
@Controller('sales-orders')
export class SalesOrdersController {
  constructor(
    private readonly salesOrdersService: SalesOrdersService,
    private readonly updateSalesOrderItemService: UpdateSalesOrderItemService,
    private readonly removeSalesOrderItemService: RemoveSalesOrderItemService,
    private readonly addDiscountToItemService: AddDiscountToItemService,
    private readonly confirmSalesOrderService: ConfirmSalesOrderService,
    private readonly voidSalesOrderService: VoidSalesOrderService,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create a new sales order' })
  @ApiBody({ type: CreateSalesOrderDto, description: 'Sales order creation payload' })
  @ApiCreatedResponse({ description: 'The sales order has been created.' })
  create(
    @Body() createSalesOrderDto: CreateSalesOrderDto,
    @CurrentUser() causer: User,
  ): Promise<SalesOrderWithItemsMapper> {
    return this.salesOrdersService.upsert(createSalesOrderDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all sales orders' })
  @ApiOkResponse({
    description: 'List of sales orders with pagination.',
    type: PaginatedResponse(SalesOrderWithItemsResponseDto),
  })
  findAll(@Query() query: SalesOrderQueryDto, @CurrentUser() causer: User) {
    return this.salesOrdersService.findAll(query, causer);
  }

  @Get('current')
  @ApiOperation({ summary: 'Get the current sales order' })
  @ApiOkResponse({ description: 'The current sales order.', type: SalesOrderWithItemsResponseDto })
  findCurrent(@CurrentUser() causer: User) {
    return this.salesOrdersService.findCurrentWithItems(causer.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a sales order by ID' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiOkResponse({ description: 'The sales order.' })
  findOne(@Param('id') id: string) {
    return this.salesOrdersService.findOne(id);
  }

  @Get(':id/with-items')
  @ApiOperation({ summary: 'Get a sales order by ID with line items' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiOkResponse({
    description: 'Sales order with line items.',
    type: SalesOrderWithItemsResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Sales order not found.' })
  findOneWithItems(@Param('id') id: string) {
    return this.salesOrdersService.findOneWithItems(id);
  }

  @Get(':id/item/:itemId')
  @ApiOperation({ summary: 'Get a sales order item by ID' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Sales order item ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiOkResponse({
    description: 'Sales order item.',
    type: SalesOrderWithItemsResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Sales order not found.' })
  findOneItem(@Param('id') id: string, @Param('itemId') itemId: string) {
    return this.salesOrdersService.findOneItem(id, itemId);
  }

  @Patch(':id/discount')
  @ApiOperation({ summary: 'Add a discount to a sales order by ID' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiBody({ type: ApplyDiscountDto, description: 'Discount application payload' })
  @ApiCreatedResponse({ description: 'The discount has been added to the sales order.' })
  async addDiscount(
    @Param('id') id: string,
    @Body() applyDiscountDto: ApplyDiscountDto,
    @CurrentUser() causer: User,
  ) {
    const soId = await this.addDiscountToItemService.execute(id, applyDiscountDto, causer);
    return this.salesOrdersService.findOneWithItems(soId);
  }

  @Patch(':id/confirm')
  @ApiOperation({ summary: 'Confirm a sales order by ID' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiBody({ type: ConfirmSalesOrderDto, description: 'Sales order confirmation payload' })
  @ApiOkResponse({ description: 'The sales order has been confirmed.' })
  async confirm(
    @Param('id') id: string,
    @Body() confirmSalesOrderDto: ConfirmSalesOrderDto,
    @CurrentUser() causer: User,
  ) {
    const soId = await this.confirmSalesOrderService.execute(id, confirmSalesOrderDto, causer);
    return this.salesOrdersService.findOneWithItems(soId);
  }

  @Patch(':id/void')
  @ApiOperation({ summary: 'Void a sales order — requires admin or supervisor PIN' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiBody({ type: VoidSalesOrderDto, description: 'Void authorization payload' })
  @ApiOkResponse({ description: 'The sales order has been voided.' })
  async void(@Param('id') id: string, @Body() voidSalesOrderDto: VoidSalesOrderDto) {
    const soId = await this.voidSalesOrderService.execute(id, voidSalesOrderDto);
    return this.salesOrdersService.findOneWithItems(soId);
  }

  @Patch(':id/item/:itemId')
  @ApiOperation({ summary: 'Update a sales order item by ID' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Sales order item ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiBody({
    type: SalesOrderWithItemsResponseDto,
    description: 'Partial sales order item update payload',
  })
  @ApiOkResponse({ description: 'The sales order item has been updated.' })
  async updateItem(
    @Param('id') id: string,
    @Param('itemId') itemId: string,
    @Body() updateSalesOrderItemDto: UpdateSalesOrderDto,
    @CurrentUser() causer: User,
  ) {
    updateSalesOrderItemDto.id = id;
    updateSalesOrderItemDto.soItemId = itemId;

    const savedSoItemId = await this.updateSalesOrderItemService.execute(
      updateSalesOrderItemDto,
      causer,
    );

    return this.salesOrdersService.findOneWithItems(savedSoItemId);
  }

  @Delete(':id/item/:itemId')
  @ApiOperation({ summary: 'Remove a sales order item by ID' })
  @ApiParam({
    name: 'id',
    description: 'Sales order ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiParam({
    name: 'itemId',
    description: 'Sales order item ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiResponse({ status: 200, description: 'The sales order item has been removed.' })
  removeItem(
    @Param('id') id: string,
    @Param('itemId') itemId: string,
    @CurrentUser() causer: User,
  ) {
    return this.removeSalesOrderItemService.execute({ id, soItemId: itemId, deletedBy: causer });
  }
}
