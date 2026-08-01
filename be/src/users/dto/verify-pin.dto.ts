import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class VerifyPinDto {
  @ApiProperty({ description: 'Employee user ID' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ description: 'Device PIN to verify', minLength: 4 })
  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  pin: string;
}
