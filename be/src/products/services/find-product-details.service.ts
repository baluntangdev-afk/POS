import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../entities/product.entity';
import { CurrenciesService } from '../../currencies/currencies.service';
import { StoreMenusService } from '../../store-menus/store-menus.service';
import { ProductDetailMapper } from '../mapper/product-detail.mapper';
import { ProductDetailsDto } from '../dto/product-details/product-details.dto';

@Injectable()
export class FindProductDetailsService {
  constructor(
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
    private readonly currenciesService: CurrenciesService,
    private readonly storeMenusService: StoreMenusService,
  ) {}

  async execute(id: number): Promise<ProductDetailsDto> {
    const [currency, defaultStoreMenu] = await Promise.all([
      this.currenciesService.findDefaultCurrency(),
      this.storeMenusService.findDefaultStoreMenu(),
    ]);

    const product = await this.productsRepository
      .createQueryBuilder('product')
      .select([
        // product columns
        'product.id',
        'product.name',
        'product.description',
        'product.imageUrl',
        'product.status',

        // product variant columns
        'pv.id',
        'pv.name',
        'pv.isDefault',

        // menu item columns
        'mi.id',
        'mi.displayPrice',

        // menu item modifier columns
        'mim.id',

        // modifier group columns
        'mg.id',
        'mg.name',
        'mg.minSelection',
        'mg.maxSelection',

        // modifier option columns
        'mo.id',
        'mo.name',
        'mo.priceAddOn',
        'mo.materialId',
        'mo.recipeItemId',
        'mo.imageUrl',
      ])
      .leftJoin('product.productVariants', 'pv')
      .leftJoin('pv.menuItems', 'mi', 'mi.store_menu_id = :storeMenuId', {
        storeMenuId: defaultStoreMenu.id,
      })
      .leftJoin('mi.menuItemModifiers', 'mim')
      .leftJoin('mim.modifierGroup', 'mg')
      .leftJoin('mg.modifierOptions', 'mo')
      .where('product.id = :id', { id })
      .getOne();

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    return ProductDetailMapper.toDto(product, { currencySign: currency.sign ?? '₱' });
  }
}
