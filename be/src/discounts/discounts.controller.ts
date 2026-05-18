import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiResponse,
} from '@nestjs/swagger';
import { DiscountsService } from './discounts.service';
import { CreateDiscountDto } from './dto/create-discount.dto';
import { UpdateDiscountDto } from './dto/update-discount.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Discounts')
@Controller('discounts')
export class DiscountsController {
  constructor(private readonly discountsService: DiscountsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new discount' })
  @ApiBody({ type: CreateDiscountDto, description: 'Discount creation payload' })
  @ApiCreatedResponse({ description: 'The discount has been created.' })
  create(@Body() createDiscountDto: CreateDiscountDto, @CurrentUser() causer: User) {
    return this.discountsService.create(createDiscountDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all discounts' })
  @ApiOkResponse({ description: 'List of discounts.' })
  findAll() {
    return this.discountsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a discount by ID' })
  @ApiParam({ name: 'id', description: 'Discount ID', example: 1 })
  @ApiOkResponse({ description: 'The discount.' })
  findOne(@Param('id') id: string) {
    return this.discountsService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a discount by ID' })
  @ApiParam({ name: 'id', description: 'Discount ID', example: 1 })
  @ApiBody({ type: UpdateDiscountDto, description: 'Partial discount update payload' })
  @ApiOkResponse({ description: 'The discount has been updated.' })
  update(
    @Param('id') id: string,
    @Body() updateDiscountDto: UpdateDiscountDto,
    @CurrentUser() causer: User,
  ) {
    updateDiscountDto.updatedBy = causer;
    return this.discountsService.update(+id, updateDiscountDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a discount by ID' })
  @ApiParam({ name: 'id', description: 'Discount ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The discount has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.discountsService.remove(+id, causer);
  }
}
