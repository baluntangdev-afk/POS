import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaxCategory } from './entities/tax-category.entity';

@Injectable()
export class TaxCategoriesService {
  constructor(
    @InjectRepository(TaxCategory)
    private readonly taxCategoryRepository: Repository<TaxCategory>,
  ) {}

  async findValueByName(name: 'VAT-exempt' | '12% VAT'): Promise<string> {
    const taxCategory = await this.taxCategoryRepository.findOne({
      where: { name },
      select: { value: true },
    });

    if (!taxCategory) {
      throw new NotFoundException('Tax category not found');
    }

    return taxCategory.value;
  }
}
