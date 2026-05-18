import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

/**
 * DTO for user-id/password login.
 */
export class LoginByUserIdDto {
  @ApiProperty({ description: 'User ID', example: '1234567890' })
  @IsString()
  @MinLength(1, { message: 'User ID must not be empty' })
  userId: string;

  @ApiProperty({ description: 'Password', example: 'password' })
  @IsString()
  @MinLength(1, { message: 'Password must not be empty' })
  password: string;
}
