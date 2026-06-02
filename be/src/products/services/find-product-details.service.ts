import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../entities/product.entity';
import { CurrenciesService } from '../../currencies/currencies.service';
import { ProductDetailMapper } from '../mapper/product-detail.mapper';
import { ProductDetailsDto } from '../dto/product-details/product-details.dto';

@Injectable()
export class FindProductDetailsService {
  constructor(
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
    private readonly currenciesService: CurrenciesService,
  ) {}

  async execute(id: number): Promise<ProductDetailsDto> {
    const currency = await this.currenciesService.findDefaultCurrency();

    const product = await this.productsRepository
      .createQueryBuilder('product')
      .select([
        'product.id',
        'product.name',
        'product.description',
        'product.imageUrl',
        'product.status',
        'product.price',
      ])
      .leftJoin('product.productGroup', 'pg')
      .addSelect(['pg.id', 'pg.name'])
      .leftJoin('pg.modifiers', 'mg')
      .addSelect(['mg.id', 'mg.name', 'mg.minSelection', 'mg.maxSelection'])
      .leftJoin('mg.modifierOptions', 'mo')
      .addSelect(['mo.id', 'mo.name', 'mo.priceAddOn', 'mo.materialId', 'mo.recipeItemId', 'mo.imageUrl'])
      .leftJoin('product.productVariants', 'pv')
      .addSelect(['pv.id', 'pv.name', 'pv.price', 'pv.isDefault'])
      .where('product.id = :id', { id })
      .orderBy('pv.isDefault', 'DESC')
      .addOrderBy('pv.id', 'ASC')
      .getOne();

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    return ProductDetailMapper.toDto(product, { currencySign: currency.sign ?? '₱' });
  }
}
