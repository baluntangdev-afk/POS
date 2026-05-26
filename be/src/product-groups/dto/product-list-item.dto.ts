import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Shape of each product item returned by the list products by group endpoint.
 */
export class ProductListItemDto {
  @ApiProperty({ description: 'Product ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Product name', example: 'Espresso' })
  name: string;

  @ApiProperty({ description: 'Display price', example: '149.00' })
  price: string;

  @ApiPropertyOptional({
    description: 'Image URL or base64-encoded image data',
    nullable: true,
  })
  imageUrl: string | null;
}
