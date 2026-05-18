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
import { MaterialsService } from './materials.service';
import { CreateMaterialDto } from './dto/create-material.dto';
import { UpdateMaterialDto } from './dto/update-material.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Materials')
@Controller('materials')
export class MaterialsController {
  constructor(private readonly materialsService: MaterialsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new material' })
  @ApiBody({ type: CreateMaterialDto, description: 'Material creation payload' })
  @ApiCreatedResponse({ description: 'The material has been created.' })
  create(@Body() createMaterialDto: CreateMaterialDto, @CurrentUser() causer: User) {
    return this.materialsService.create(createMaterialDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all materials' })
  @ApiOkResponse({ description: 'List of materials.' })
  findAll() {
    return this.materialsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a material by ID' })
  @ApiParam({ name: 'id', description: 'Material ID', example: 1 })
  @ApiOkResponse({ description: 'The material.' })
  findOne(@Param('id') id: string) {
    return this.materialsService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a material by ID' })
  @ApiParam({ name: 'id', description: 'Material ID', example: 1 })
  @ApiBody({ type: UpdateMaterialDto, description: 'Partial material update payload' })
  @ApiOkResponse({ description: 'The material has been updated.' })
  update(
    @Param('id') id: string,
    @Body() updateMaterialDto: UpdateMaterialDto,
    @CurrentUser() causer: User,
  ) {
    updateMaterialDto.updatedBy = causer;
    return this.materialsService.update(+id, updateMaterialDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a material by ID' })
  @ApiParam({ name: 'id', description: 'Material ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The material has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.materialsService.remove(+id, causer);
  }
}
