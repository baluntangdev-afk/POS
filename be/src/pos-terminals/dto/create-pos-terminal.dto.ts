import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePosTerminalDto {
  @ApiProperty({ example: 'ABC Corporation' })
  @IsString()
  @IsNotEmpty()
  legalName: string;

  @ApiProperty({ example: '123 Main St., City' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ example: '123-456-789-000' })
  @IsString()
  @IsNotEmpty()
  tinNumber: string;
}
