import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../products/entities/product.entity';
import { ProductGroup } from '../../product-groups/entities/product-group.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { User } from '../../users/entities/user.entity';
import { ProductStatus, ProductVariantStatus } from '../../products/products.enum';
import { AppConfigService } from '../../config/config.service';
import { ErpClientService, ErpMenuItem } from './erp-client.service';

export interface MenuSyncResult {
  synced_at: string;
  total: number;
  created: number;
  updated: number;
  unavailable: number;
  errors: string[];
}

/**
 * Pulls the ERP menu (SKU, price, recipe-based availability) and mirrors it onto
 * POS products: upserts by SKU, sets price and is_available. The ERP is the
 * source of truth for ERP-managed (sku-bearing) products.
 */
@Injectable()
export class ErpMenuSyncService {
  private readonly logger = new Logger(ErpMenuSyncService.name);
  private syncing = false;
  private lastResult: MenuSyncResult | null = null;

  private static readonly DEFAULT_GROUP = 'ERP Menu';

  constructor(
    private readonly config: AppConfigService,
    private readonly erpClient: ErpClientService,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(ProductGroup)
    private readonly productGroupRepository: Repository<ProductGroup>,
    @InjectRepository(ProductVariant)
    private readonly productVariantRepository: Repository<ProductVariant>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  get status(): MenuSyncResult | null {
    return this.lastResult;
  }

  /** Every 5 minutes; menu also stays usable offline from the last synced snapshot. */
  @Cron('*/5 * * * *')
  async scheduledSync(): Promise<void> {
    if (!this.config.erpSyncEnabled || !this.erpClient.isConfigured) return;
    try {
      await this.syncMenu();
    } catch (err) {
      this.logger.warn(`Scheduled ERP menu sync failed: ${(err as Error).message}`);
    }
  }

  async syncMenu(): Promise<MenuSyncResult> {
    if (this.syncing) {
      throw new Error('ERP menu sync already in progress');
    }
    if (!this.erpClient.isConfigured) {
      throw new Error('ERP sync is not configured (ERP_BASE_URL / ERP_USERNAME / ERP_PASSWORD)');
    }

    this.syncing = true;
    const result: MenuSyncResult = {
      synced_at: new Date().toISOString(),
      total: 0,
      created: 0,
      updated: 0,
      unavailable: 0,
      errors: [],
    };

    try {
      const menu = await this.erpClient.getMenu();
      result.total = menu.items.length;

      const systemUser = await this.userRepository.findOne({ where: {}, order: { id: 'ASC' } });
      if (!systemUser) throw new Error('No POS user found to own synced products');

      const groupCache = new Map<string, ProductGroup>();

      for (const item of menu.items) {
        try {
          const changed = await this.upsertProduct(item, systemUser, groupCache);
          if (changed === 'created') result.created++;
          else if (changed === 'updated') result.updated++;
          if (!item.is_available) result.unavailable++;
        } catch (err) {
          result.errors.push(`${item.sku}: ${(err as Error).message}`);
        }
      }

      // ERP-managed products missing from the menu are no longer sellable.
      const skus = menu.items.map((i) => i.sku);
      const orphanQuery = this.productRepository
        .createQueryBuilder()
        .update(Product)
        .set({ isAvailable: false, availableServings: 0 })
        .where('sku IS NOT NULL')
        .andWhere('deleted_at IS NULL');
      if (skus.length > 0) orphanQuery.andWhere('sku NOT IN (:...skus)', { skus });
      await orphanQuery.execute();

      this.lastResult = result;
      this.logger.log(
        `ERP menu sync: ${result.total} items — ${result.created} created, ${result.updated} updated, ${result.unavailable} unavailable`,
      );
      return result;
    } finally {
      this.syncing = false;
    }
  }

  private async upsertProduct(
    item: ErpMenuItem,
    systemUser: User,
    groupCache: Map<string, ProductGroup>,
  ): Promise<'created' | 'updated'> {
    const group = await this.resolveGroup(item.category, systemUser, groupCache);
    const price = Number(item.price ?? 0).toFixed(2);

    const existing = await this.productRepository.findOne({
      where: { sku: item.sku },
      relations: { productGroup: true },
    });

    if (existing) {
      existing.name = item.name || existing.name;
      existing.description = item.description ?? existing.description;
      existing.price = price;
      existing.isAvailable = item.is_available;
      existing.availableServings = Math.max(0, Number(item.available_servings) || 0);
      existing.productGroup = group;
      existing.updatedBy = systemUser;
      await this.productRepository.save(existing);
      await this.syncDefaultVariantPrice(existing, price, systemUser);
      return 'updated';
    }

    const product = this.productRepository.create({
      sku: item.sku,
      name: item.name,
      description: item.description,
      price,
      isAvailable: item.is_available,
      availableServings: Math.max(0, Number(item.available_servings) || 0),
      status: ProductStatus.ACTIVE,
      productGroup: group,
      createdBy: systemUser,
    });
    const saved = await this.productRepository.save(product);
    await this.syncDefaultVariantPrice(saved, price, systemUser);
    return 'created';
  }

  /** Kiosk ordering goes through product_variants; keep a default variant priced with the product. */
  private async syncDefaultVariantPrice(
    product: Product,
    price: string,
    systemUser: User,
  ): Promise<void> {
    const variant = await this.productVariantRepository.findOne({
      where: { product: { id: product.id }, isDefault: true },
    });

    if (variant) {
      variant.price = Number(price);
      variant.updatedBy = systemUser;
      await this.productVariantRepository.save(variant);
      return;
    }

    await this.productVariantRepository.save(
      this.productVariantRepository.create({
        product,
        name: 'Default',
        isDefault: true,
        price: Number(price),
        status: ProductVariantStatus.ACTIVE,
        createdBy: systemUser,
      }),
    );
  }

  private async resolveGroup(
    category: string | null,
    systemUser: User,
    cache: Map<string, ProductGroup>,
  ): Promise<ProductGroup> {
    const name = (category || '').trim() || ErpMenuSyncService.DEFAULT_GROUP;
    const cached = cache.get(name.toLowerCase());
    if (cached) return cached;

    let group = await this.productGroupRepository.findOne({ where: { name } });
    if (!group) {
      group = await this.productGroupRepository.save(
        this.productGroupRepository.create({ name, createdBy: systemUser }),
      );
    }

    cache.set(name.toLowerCase(), group);
    return group;
  }
}
