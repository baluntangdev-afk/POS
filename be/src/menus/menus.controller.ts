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
import { MenusService } from './menus.service';
import { CreateMenuDto } from './dto/create-menu.dto';
import { UpdateMenuDto } from './dto/update-menu.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Menus')
@Controller('menus')
export class MenusController {
  constructor(private readonly menusService: MenusService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new menu' })
  @ApiBody({ type: CreateMenuDto, description: 'Menu creation payload' })
  @ApiCreatedResponse({ description: 'The menu has been created.' })
  create(@Body() createMenuDto: CreateMenuDto, @CurrentUser() causer: User) {
    return this.menusService.create(createMenuDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all menus' })
  @ApiOkResponse({ description: 'List of menus.' })
  findAll() {
    return this.menusService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a menu by ID' })
  @ApiParam({ name: 'id', description: 'Menu ID', example: 1 })
  @ApiOkResponse({ description: 'The menu.' })
  findOne(@Param('id') id: string) {
    return this.menusService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a menu by ID' })
  @ApiParam({ name: 'id', description: 'Menu ID', example: 1 })
  @ApiBody({ type: UpdateMenuDto, description: 'Partial menu update payload' })
  @ApiOkResponse({ description: 'The menu has been updated.' })
  update(
    @Param('id') id: string,
    @Body() updateMenuDto: UpdateMenuDto,
    @CurrentUser() causer: User,
  ) {
    updateMenuDto.updatedBy = causer;
    return this.menusService.update(+id, updateMenuDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a menu by ID' })
  @ApiParam({ name: 'id', description: 'Menu ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The menu has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.menusService.remove(+id, causer);
  }
}
