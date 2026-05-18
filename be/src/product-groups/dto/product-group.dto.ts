import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Product group DTO.
 */
export class ProductGroupDto {
  @ApiProperty({ description: 'Product group ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Product group name', example: 'Meals' })
  name: string;

  @ApiPropertyOptional({
    description: 'Product group description',
    example: 'Meals description',
  })
  description?: string;

  @ApiPropertyOptional({
    description: 'Image URL or base64-encoded image data',
    format: 'binary',
  })
  imageUrl?: string;
}
