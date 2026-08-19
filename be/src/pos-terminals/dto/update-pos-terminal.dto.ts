import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdatePosTerminalDto {
  @ApiPropertyOptional({ example: '019fe9c9-93e3-7d53-8f34-c1819751a318' })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  kioskId?: string;

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
