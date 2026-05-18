import { Injectable } from '@nestjs/common';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { RecipesService } from '../../recipes/recipes.service';
import { InventoryStocksService } from '../../inventory-stocks/inventory-stocks.service';
import { MaterialDemandDto } from '../../inventory-stocks/dto/material-demand.dto';
import { InsufficientInventoryException } from '../exceptions/insufficient-inventory.exception';

/**
 * Validates that store-level inventory can satisfy sales order item demands. Single responsibility.
 */
@Injectable()
export class SalesOrderInventoryValidationService {
  constructor(
    private readonly recipesService: RecipesService,
    private readonly inventoryStocksService: InventoryStocksService,
  ) {}

  /**
   * Validates that store-level inventory can satisfy all recipe-item demands for the given items.
   * @throws InsufficientInventoryException when one or more materials have insufficient stock
   */
  async validateInventoryAvailability(soItems: SalesOrderItem[]): Promise<void> {
    const recipeItemsByRecipeId = await this.recipesService.findRecipeItemsByRecipeIds(
      soItems.map((soi) => soi.recipe.id),
    );
    const demands: MaterialDemandDto[] = [];
    for (const soi of soItems) {
      const baseRecipeItems = recipeItemsByRecipeId.get(soi.recipe.id) ?? [];
      for (const recipeItem of baseRecipeItems) {
        demands.push({
          materialId: recipeItem.material.id,
          quantity: parseFloat(recipeItem.quantity) * parseFloat(soi.qty),
          unitId: recipeItem.unit.id,
        });
        if (soi.recipeItem) {
          demands.push({
            materialId: soi.recipeItem.material.id,
            quantity: parseFloat(soi.recipeItem.quantity) * parseFloat(soi.qty),
            unitId: soi.recipeItem.unit.id,
          });
        }
      }
    }
    const result = await this.inventoryStocksService.validateAvailability(demands);
    if (!result.sufficient && result.insufficientItems?.length) {
      throw new InsufficientInventoryException(result.insufficientItems);
    }
  }
}
