import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { MenuStatus } from '../menus.enum';

/**
 * DTO for creating a new menu.
 */
export class CreateMenuDto {
  @ApiProperty({ description: 'Menu code', example: 'M001' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(4)
  menuCode: string;

  @ApiProperty({ description: 'Menu name', example: 'Dashboard' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(50)
  menuName: string;

  @ApiProperty({
    description: 'Permission identifiers',
    example: ['read:dashboard', 'write:reports'],
  })
  @IsNotEmpty()
  @IsArray()
  @IsString({ each: true })
  permissions: string[];

  @ApiPropertyOptional({ enum: MenuStatus, default: MenuStatus.ACTIVE })
  @IsOptional()
  @IsEnum(MenuStatus)
  status?: MenuStatus;
}
