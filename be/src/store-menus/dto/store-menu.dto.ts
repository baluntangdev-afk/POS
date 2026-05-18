import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { StoreMenuStatus } from '../store-menus.enum';

/**
 * Store Menu DTO.
 */
export class StoreMenuDto {
  @ApiProperty({ description: 'Store menu ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Store menu name', example: 'Breakfast Menu' })
  name: string;

  @ApiPropertyOptional({
    description: 'Store menu description',
    example: 'Available breakfast items from 6AM to 11AM',
  })
  description?: string;

  @ApiProperty({ enum: StoreMenuStatus, example: StoreMenuStatus.ACTIVE })
  status: StoreMenuStatus;
}
