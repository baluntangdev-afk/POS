import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdatePosTerminalDto {
  @ApiPropertyOptional({ example: 'ABC Corporation' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  legalName?: string;

  @ApiPropertyOptional({ example: '123 Main St., City' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional({ example: '123-456-789-000' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  tinNumber?: string;
}
