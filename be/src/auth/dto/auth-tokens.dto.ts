import { ApiProperty } from '@nestjs/swagger';

/**
 * Response shape for login and refresh endpoints.
 */
export class AuthTokensDto {
  @ApiProperty({ description: 'Access token', example: 'access-token' })
  accessToken: string;

  @ApiProperty({ description: 'Refresh token', example: 'refresh-token' })
  refreshToken: string;

  @ApiProperty({ description: 'Expires in', example: '1h' })
  expiresIn: string;

  @ApiProperty({ description: 'User ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'PIN changed', example: false })
  isPinChanged: boolean;
}
