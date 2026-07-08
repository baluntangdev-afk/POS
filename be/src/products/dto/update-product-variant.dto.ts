import { ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';
import { CreateProductVariantDto } from './create-product.variant.dto';

/**
 * DTO for updating a product variant.
 */
export class UpdateProductVariantDto extends PartialType(CreateProductVariantDto) {
  @ApiPropertyOptional({
    description: 'Whether the variant is enabled (shown to customers)',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
