import { ApiProperty } from '@nestjs/swagger';

/**
 * Product Variant DTO.
 */
export class ProductVariantDto {
  @ApiProperty({ description: 'Product Variant ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Product ID', example: 1 })
  productId: number;

  @ApiProperty({ description: 'Product Variant name', example: 'Large' })
  name: string;

  @ApiProperty({ description: 'Variant price', example: 150.0 })
  price: number;

  @ApiProperty({
    description: 'Whether this is the default variant',
    example: false,
  })
  isDefault: boolean;

  @ApiProperty({
    description: 'Whether this variant is enabled (shown to customers)',
    example: true,
  })
  isActive: boolean;
}
