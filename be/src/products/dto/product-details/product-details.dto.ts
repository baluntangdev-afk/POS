import { ApiProperty } from '@nestjs/swagger';
import { ProductVariantDto } from './variant.dto';

export class ProductDetailsDto {
  @ApiProperty({ description: 'Product ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Product name', example: 'Sinigang' })
  name: string;

  @ApiProperty({
    description: 'Product description',
    example: 'Sinigang is a Filipino soup made with tamarind, pork, and vegetables.',
  })
  description: string | null;

  @ApiProperty({ description: 'Product image URL', example: 'https://example.com/sinigang.jpg' })
  imageUrl: string | null;

  @ApiProperty({ description: 'Currency sign', example: '₱' })
  currencySign: string;

  @ApiProperty({ description: 'Display price', example: '100' })
  displayPrice: string;

  @ApiProperty({ type: () => [ProductVariantDto] })
  variants: ProductVariantDto[];
}
