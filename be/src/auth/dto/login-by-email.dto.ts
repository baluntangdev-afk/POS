import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

/**
 * DTO for email/password login.
 */
export class LoginByEmailDto {
  @ApiProperty({ description: 'Email address', example: 'test@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ description: 'Password', example: 'password' })
  @IsString()
  @MinLength(1, { message: 'Password must not be empty' })
  password: string;
}
