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
import { ModifierGroupsService } from './modifier-groups.service';
import { CreateModifierGroupDto } from './dto/create-modifier-group.dto';
import { UpdateModifierGroupDto } from './dto/update-modifier-group.dto';
import { ModifierGroupDto } from './dto/modifier-group.dto';
import { ModifierGroupQueryDto } from './dto/modifier-group-query.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { PaginatedResult } from '../utils/pagination';

@ApiTags('Modifier Groups')
@Controller('modifier-groups')
export class ModifierGroupsController {
  constructor(private readonly modifierGroupsService: ModifierGroupsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new modifier group with options' })
  @ApiBody({
    type: CreateModifierGroupDto,
    description: 'Modifier group creation payload with options',
  })
  @ApiCreatedResponse({
    description: 'The modifier group has been created.',
    type: ModifierGroupDto,
  })
  create(
    @Body() createModifierGroupDto: CreateModifierGroupDto,
    @CurrentUser() causer: User,
  ): Promise<ModifierGroupDto> {
    return this.modifierGroupsService.create(createModifierGroupDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all modifier groups' })
  @ApiOkResponse({ description: 'Paginated list of modifier groups.' })
  findAll(@Query() query: ModifierGroupQueryDto): Promise<PaginatedResult<ModifierGroupDto>> {
    return this.modifierGroupsService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a modifier group by ID' })
  @ApiParam({ name: 'id', description: 'Modifier group ID', example: 1 })
  @ApiOkResponse({ description: 'The modifier group.', type: ModifierGroupDto })
  findOne(@Param('id') id: string): Promise<ModifierGroupDto> {
    return this.modifierGroupsService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a modifier group by ID' })
  @ApiParam({ name: 'id', description: 'Modifier group ID', example: 1 })
  @ApiBody({
    type: UpdateModifierGroupDto,
    description: 'Partial modifier group update payload with options',
  })
  @ApiOkResponse({ description: 'The modifier group has been updated.', type: ModifierGroupDto })
  update(
    @Param('id') id: string,
    @Body() updateModifierGroupDto: UpdateModifierGroupDto,
    @CurrentUser() causer: User,
  ): Promise<ModifierGroupDto> {
    return this.modifierGroupsService.update(+id, updateModifierGroupDto, causer);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a modifier group by ID' })
  @ApiParam({ name: 'id', description: 'Modifier group ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The modifier group has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User): Promise<{ message: string }> {
    return this.modifierGroupsService.remove(+id, causer);
  }
}
