import { PartialType } from '@nestjs/swagger';
import { CreateProductVariantDto } from './create-product.variant.dto';

/**
 * DTO for updating a product variant.
 */
export class UpdateProductVariantDto extends PartialType(CreateProductVariantDto) {}
