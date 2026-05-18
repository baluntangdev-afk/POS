import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Product DTO.
 */
export class ProductDto {
  @ApiProperty({ description: 'Product ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Product group ID', example: 1 })
  groupId: number;

  @ApiProperty({ description: 'Product name', example: 'Sinigang' })
  name: string;

  @ApiPropertyOptional({
    description: 'Product description',
    example: 'Filipino sour soup',
  })
  description?: string;

  @ApiPropertyOptional({
    description: 'Image URL or base64-encoded image data',
    format: 'binary',
  })
  imageUrl?: string;
}
