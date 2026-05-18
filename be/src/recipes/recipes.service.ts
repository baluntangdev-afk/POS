import { Injectable } from '@nestjs/common';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { User } from '../users/entities/user.entity';
import { Recipe } from './entities/recipe.entity';
import { In, Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { RecipeItem } from './entities/recipe-item.entity';

@Injectable()
export class RecipesService {
  constructor(
    @InjectRepository(Recipe)
    private readonly recipeRepository: Repository<Recipe>,
    @InjectRepository(RecipeItem)
    private readonly recipeItemRepository: Repository<RecipeItem>,
  ) {}

  create(createRecipeDto: CreateRecipeDto, causer: User) {
    return 'This action adds a new recipe';
  }

  findAll() {
    return `This action returns all recipes`;
  }

  findOne(id: number) {
    return `This action returns a #${id} recipe`;
  }

  async findRecipeIdsByProductVariantIds(
    productVariantIds: number[],
  ): Promise<Map<number, Recipe['id']>> {
    const recipes = await this.recipeRepository.find({
      where: {
        productVariant: { id: In(productVariantIds) },
      },
      select: {
        id: true,
        productVariant: { id: true },
      },
      relations: {
        productVariant: true,
      },
    });

    return new Map(recipes.map((r) => [r.productVariant.id, r.id]));
  }

  /**
   * Returns all recipe items (base and add-on) per recipe, keyed by recipe id.
   */
  async findRecipeItemsByRecipeIds(
    recipeIds: number[],
    isAddOn: boolean = false,
  ): Promise<Map<number, RecipeItem[]>> {
    if (recipeIds.length === 0) {
      return new Map();
    }

    const recipeItems = await this.recipeItemRepository.find({
      where: {
        recipe: { id: In(recipeIds) },
        extra: isAddOn,
      },
      select: {
        id: true,
        quantity: true,
        recipe: { id: true },
        material: { id: true },
        unit: { id: true },
      },
      relations: {
        recipe: true,
        material: true,
        unit: true,
      },
    });

    const map = new Map<number, RecipeItem[]>();
    recipeItems.forEach((ri) => {
      const recipeId = ri.recipe.id;
      const list = map.get(recipeId) ?? [];
      list.push(ri);
      map.set(recipeId, list);
    });

    return map;
  }

  findRecipesByIdsWithRecipeItems(recipeIds: number[]): Promise<Recipe[]> {
    return this.recipeRepository.find({
      select: {
        id: true,
        recipeItems: {
          id: true,
          quantity: true,
          unit: { id: true },
          material: { id: true },
          extra: true,
        },
      },
      where: { id: In(recipeIds) },
      relations: { recipeItems: { unit: true, material: true } },
    });
  }

  async findRecipeItemsByModifierOptionIds(
    modifierOptionIds: number[],
  ): Promise<Map<number, RecipeItem>> {
    const recipeItems = await this.recipeItemRepository.find({
      where: {
        modifierOption: { id: In(modifierOptionIds) },
      },
      select: {
        id: true,
        recipe: { id: true, name: true, productVariant: { id: true } },
        modifierOption: { id: true },
        material: { id: true },
        unit: { id: true },
      },
      relations: {
        recipe: { productVariant: true },
        modifierOption: true,
        material: true,
        unit: true,
      },
    });

    return new Map(recipeItems.map((ri) => [ri.modifierOption.id, ri]));
  }

  update(id: number, updateRecipeDto: UpdateRecipeDto) {
    return `This action updates a #${id} recipe`;
  }

  remove(id: number, causer: User) {
    return `This action removes a #${id} recipe`;
  }
}
