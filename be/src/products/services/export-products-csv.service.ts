import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PRODUCTS_CSV_HEADERS_WITH_IMAGE } from '../../database/seeders/csv/csv-schema.registry';
import { Product } from '../entities/product.entity';

/**
 * Quotes a field when it contains a comma, quote, or line break, escaping inner
 * quotes as `""` — the inverse of `parseCsvContent`. Line breaks are flattened to
 * spaces because the import parser splits rows on newlines before honouring quotes.
 */
function escapeCsvField(value: string): string {
  const flattened = value.replace(/\r?\n/g, ' ');
  return /[",]/.test(flattened) ? `"${flattened.replace(/"/g, '""')}"` : flattened;
}

/** Only real URLs round-trip; legacy base64 image blobs are left out of the CSV. */
function exportableImageUrl(imageUrl: string | null): string {
  return imageUrl && /^https?:\/\//i.test(imageUrl) ? imageUrl : '';
}

/**
 * Exports every live (non-soft-deleted) product as a CSV in the exact format
 * `ImportProductsCsvService` accepts (the 8-column header including
 * `Product Image URL`), so the file can be edited and re-imported as-is.
 * One row per variant; a product with no live variants gets a single row with
 * blank Variant Name/Price. Within a product the default variant comes first,
 * because the importer marks the first variant row as the default.
 */
@Injectable()
export class ExportProductsCsvService {
  constructor(
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
  ) {}

  async execute(): Promise<string> {
    const products = await this.productRepository
      .createQueryBuilder('product')
      .innerJoinAndSelect('product.productGroup', 'productGroup')
      .leftJoinAndSelect('product.productVariants', 'variant')
      .orderBy('productGroup.name', 'ASC')
      .addOrderBy('product.sortOrder', 'ASC')
      .addOrderBy('product.id', 'ASC')
      .addOrderBy('variant.isDefault', 'DESC')
      .addOrderBy('variant.id', 'ASC')
      .getMany();

    const lines: string[] = [PRODUCTS_CSV_HEADERS_WITH_IMAGE.join(',')];

    for (const product of products) {
      const productFields = [
        product.productGroup.name,
        product.productGroup.description ?? '',
        product.name,
        product.description ?? '',
        String(product.price),
      ];
      const imageUrl = exportableImageUrl(product.imageUrl);
      const variants = product.productVariants ?? [];

      if (variants.length === 0) {
        lines.push([...productFields, '', '', imageUrl].map(escapeCsvField).join(','));
        continue;
      }
      for (const variant of variants) {
        lines.push(
          [...productFields, variant.name, String(variant.price), imageUrl]
            .map(escapeCsvField)
            .join(','),
        );
      }
    }

    return `${lines.join('\r\n')}\r\n`;
  }
}
