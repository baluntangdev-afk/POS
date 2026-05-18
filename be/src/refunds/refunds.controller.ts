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
import { RefundsService } from './refunds.service';
import { CreateRefundDto } from './dto/create-refund.dto';
import { UpdateRefundDto } from './dto/update-refund.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { RefundWithItemsResponseDto } from './dto/refund-with-items-response.dto';
import { RefundQueryDto } from './dto/refund-query.dto';
import { PaginatedResponse } from '../utils/pagination/dto';

@ApiTags('Refunds')
@Controller('refunds')
export class RefundsController {
  constructor(private readonly refundsService: RefundsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new refund' })
  @ApiBody({ type: CreateRefundDto, description: 'Refund creation payload' })
  @ApiCreatedResponse({
    type: RefundWithItemsResponseDto,
    description: 'The refund has been created.',
  })
  create(@Body() createRefundDto: CreateRefundDto, @CurrentUser() causer: User) {
    return this.refundsService.create(createRefundDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all refunds' })
  @ApiOkResponse({
    description: 'List of refunds with pagination.',
    type: PaginatedResponse(RefundWithItemsResponseDto),
  })
  findAll(@Query() query: RefundQueryDto) {
    return this.refundsService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a refund by ID' })
  @ApiParam({ name: 'id', description: 'Refund ID', example: 1 })
  @ApiOkResponse({ description: 'The refund.' })
  findOne(@Param('id') id: string) {
    return this.refundsService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a refund by ID' })
  @ApiParam({ name: 'id', description: 'Refund ID', example: 1 })
  @ApiBody({ type: UpdateRefundDto, description: 'Partial refund update payload' })
  @ApiOkResponse({ description: 'The refund has been updated.' })
  update(
    @Param('id') id: string,
    @Body() updateRefundDto: UpdateRefundDto,
    @CurrentUser() causer: User,
  ) {
    updateRefundDto.updatedBy = causer;
    return this.refundsService.update(+id, updateRefundDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a refund by ID' })
  @ApiParam({ name: 'id', description: 'Refund ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The refund has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.refundsService.remove(+id, causer);
  }
}
