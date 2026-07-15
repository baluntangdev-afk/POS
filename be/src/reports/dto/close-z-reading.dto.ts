import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class CloseZReadingDto {
  @ApiProperty({ description: 'Supervisor/admin user id authorizing this close' })
  @IsString()
  @IsNotEmpty()
  authorizerId: string;

  @ApiProperty({ description: 'Supervisor/admin device PIN', minLength: 4 })
  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  pin: string;
}
