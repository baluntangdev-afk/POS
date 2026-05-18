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
import { RecipesService } from './recipes.service';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Recipes')
@Controller('recipes')
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new recipe' })
  @ApiBody({ type: CreateRecipeDto, description: 'Recipe creation payload' })
  @ApiCreatedResponse({ description: 'The recipe has been created.' })
  create(@Body() createRecipeDto: CreateRecipeDto, @CurrentUser() causer: User) {
    return this.recipesService.create(createRecipeDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all recipes' })
  @ApiOkResponse({ description: 'List of recipes.' })
  findAll() {
    return this.recipesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a recipe by ID' })
  @ApiParam({ name: 'id', description: 'Recipe ID', example: 1 })
  @ApiOkResponse({ description: 'The recipe.' })
  findOne(@Param('id') id: string) {
    return this.recipesService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a recipe by ID' })
  @ApiParam({ name: 'id', description: 'Recipe ID', example: 1 })
  @ApiBody({ type: UpdateRecipeDto, description: 'Partial recipe update payload' })
  @ApiOkResponse({ description: 'The recipe has been updated.' })
  update(
    @Param('id') id: string,
    @Body() updateRecipeDto: UpdateRecipeDto,
    @CurrentUser() causer: User,
  ) {
    updateRecipeDto.updatedBy = causer;
    return this.recipesService.update(+id, updateRecipeDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a recipe by ID' })
  @ApiParam({ name: 'id', description: 'Recipe ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The recipe has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.recipesService.remove(+id, causer);
  }
}
