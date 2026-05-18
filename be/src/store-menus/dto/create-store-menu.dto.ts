import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { StoreMenuStatus } from '../store-menus.enum';

/**
 * DTO for creating a new store menu.
 */
export class CreateStoreMenuDto {
  @ApiProperty({ type: () => String, example: 'Breakfast Menu' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ type: () => String })
  @IsOptional()
  @IsString()
  description?: string | null;

  @ApiPropertyOptional({ enum: StoreMenuStatus, default: StoreMenuStatus.ACTIVE })
  @IsOptional()
  @IsEnum(StoreMenuStatus)
  status?: StoreMenuStatus;
}
