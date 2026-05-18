import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Length } from 'class-validator';

/**
 * DTO for device pin login.
 */
export class LoginByDevicePinDto {
  @ApiProperty({ description: 'User ID', example: '1234567890' })
  @IsString()
  @IsNotEmpty({ message: 'User ID is required' })
  userId: string;

  @ApiProperty({ description: 'Device Pin', example: '123456' })
  @IsString()
  @Length(6, 6, { message: 'Device Pin must be exactly 6 characters long' })
  devicePin: string;
}
