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
import { PaymentsService } from './payments.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { UpdatePaymentDto } from './dto/update-payment.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { PaymentQueryDto } from './dto/payment-query.dto';
import { PaymentResponseDto } from './dto/payment-response.dto';
import { PaginatedResponse } from '../utils/pagination/dto';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new payment' })
  @ApiBody({ type: CreatePaymentDto, description: 'Payment creation payload' })
  @ApiCreatedResponse({ description: 'The payment has been created.' })
  create(@Body() createPaymentDto: CreatePaymentDto, @CurrentUser() causer: User) {
    return this.paymentsService.create(createPaymentDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all payments' })
  @ApiOkResponse({
    description: 'List of payments with pagination.',
    type: PaginatedResponse(PaymentResponseDto),
  })
  findAll(@Query() query: PaymentQueryDto) {
    return this.paymentsService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a payment by ID' })
  @ApiParam({
    name: 'id',
    description: 'Payment ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiOkResponse({ description: 'The payment.' })
  findOne(@Param('id') id: string) {
    return this.paymentsService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a payment by ID' })
  @ApiParam({
    name: 'id',
    description: 'Payment ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiBody({ type: UpdatePaymentDto, description: 'Partial payment update payload' })
  @ApiOkResponse({ description: 'The payment has been updated.' })
  update(
    @Param('id') id: string,
    @Body() updatePaymentDto: UpdatePaymentDto,
    @CurrentUser() causer: User,
  ) {
    return this.paymentsService.update(id, updatePaymentDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a payment by ID' })
  @ApiParam({
    name: 'id',
    description: 'Payment ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @ApiResponse({ status: 200, description: 'The payment has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.paymentsService.remove(id, causer);
  }
}
