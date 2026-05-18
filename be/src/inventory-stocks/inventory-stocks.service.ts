import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { InventoryStock } from './entities/inventory-stock.entity';
import { MaterialDemandDto } from './dto/material-demand.dto';
import {
  InventoryValidationResult,
  InsufficientItemDto,
} from './dto/inventory-validation-result.dto';

@Injectable()
export class InventoryStocksService {
  constructor(
    @InjectRepository(InventoryStock)
    private readonly inventoryStockRepository: Repository<InventoryStock>,
  ) {}

  /**
   * Validates that current store-level inventory can satisfy the given material demands.
   * Aggregates demands by (materialId, unitId), compares to quantity_on_hand where variant_id IS NULL.
   * @param demands - List of required material quantities per unit
   * @returns Validation result with sufficient flag and optional list of insufficient materials
   */
  async validateAvailability(demands: MaterialDemandDto[]): Promise<InventoryValidationResult> {
    if (demands.length === 0) {
      return { sufficient: true };
    }

    const aggregated = this.aggregateDemandsByMaterialAndUnit(demands);
    const materialIds = [
      ...new Set(Array.from(aggregated.keys()).map((k) => Number(k.split('-')[0]))),
    ];

    const stocks = await this.inventoryStockRepository.find({
      where: {
        material: { id: In(materialIds) },
        productVariant: IsNull(),
      },
      select: {
        id: true,
        quantityOnHand: true,
        material: { id: true },
        unit: { id: true },
      },
      relations: { material: true, unit: true },
    });

    const stockByMaterialAndUnit = new Map<string, number>();
    stocks.forEach((s) => {
      if (s.material?.id != null && s.unit?.id != null) {
        const key = `${s.material.id}-${s.unit.id}`;
        const current = stockByMaterialAndUnit.get(key) ?? 0;
        const onHand = parseFloat(s.quantityOnHand);
        stockByMaterialAndUnit.set(key, current + onHand);
      }
    });

    const insufficientItems: InsufficientItemDto[] = [];
    aggregated.forEach((required, key) => {
      const onHand = stockByMaterialAndUnit.get(key) ?? 0;
      if (required > onHand) {
        const [materialIdStr] = key.split('-');
        insufficientItems.push({
          materialId: Number(materialIdStr),
          required,
          onHand,
        });
      }
    });

    return {
      sufficient: insufficientItems.length === 0,
      insufficientItems: insufficientItems.length > 0 ? insufficientItems : undefined,
    };
  }

  private aggregateDemandsByMaterialAndUnit(demands: MaterialDemandDto[]): Map<string, number> {
    const map = new Map<string, number>();
    demands.forEach((d) => {
      const key = `${d.materialId}-${d.unitId}`;
      const current = map.get(key) ?? 0;
      map.set(key, current + d.quantity);
    });
    return map;
  }
}
