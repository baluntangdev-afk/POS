import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePosTerminalDto {
  @ApiProperty({ example: '019fe9c9-93e3-7d53-8f34-c1819751a318' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  kioskId: string;

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
