import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

/**
 * DTO for refresh token request.
 */
export class RefreshTokenDto {
  @ApiProperty({ description: 'Refresh token', example: 'refresh-token' })
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}
