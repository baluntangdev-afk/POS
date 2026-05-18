import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductGroup } from '../../product-groups/entities/product-group.entity';

@Injectable()
export class FindProductGroupService {
  constructor(
    @InjectRepository(ProductGroup)
    private readonly productGroupRepository: Repository<ProductGroup>,
  ) {}

  async execute(id: number): Promise<ProductGroup> {
    const productGroup = await this.productGroupRepository.findOne({
      where: { id: id },
    });

    if (!productGroup) {
      throw new NotFoundException('Product group not found');
    }

    return productGroup;
  }
}
