import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { ModifierOption } from '../entities/modifier-option.entity';

@Injectable()
export class FindModifierOptionWithRelationService {
  constructor(
    @InjectRepository(ModifierOption)
    private readonly modifierOptionRepository: Repository<ModifierOption>,
  ) {}

  async execute(ids: number[]): Promise<Map<number, ModifierOption>> {
    const modifierOptions = await this.modifierOptionRepository.find({
      where: { id: In(ids) },
      select: {
        id: true,
        name: true,
        priceAddOn: true,
        recipeItem: {
          id: true,
          recipe: { id: true, productVariant: { id: true } },
          material: { id: true },
          unit: { id: true },
        },
      },
      relations: { recipeItem: { recipe: { productVariant: true }, material: true, unit: true } },
    });

    return new Map(modifierOptions.map((mo) => [mo.id, mo]));
  }
}
