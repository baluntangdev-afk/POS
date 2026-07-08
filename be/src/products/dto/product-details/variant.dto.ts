import { ApiProperty } from '@nestjs/swagger';

export class ProductVariantDetailsDto {
  @ApiProperty({ description: 'Variant ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Variant name', example: 'Regular' })
  name: string;

  @ApiProperty({ description: 'Display price', example: '100.00' })
  displayPrice: string;

  @ApiProperty({ description: 'Is the default variant', example: true })
  isDefault: boolean;

  @ApiProperty({ description: 'Whether this variant is enabled', example: true })
  isActive: boolean;
}
