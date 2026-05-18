import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Product } from '../entities/product.entity';
import { EntityHelper } from '../../utils/entity.helper';

@Injectable()
export class DeleteProductService {
  constructor(
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
  ) {}

  async execute(id: number, causer: User): Promise<void> {
    const payload: Partial<Product> = { deletedBy: causer };
    await this.productsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.productsRepository.softDelete(id);
  }
}
