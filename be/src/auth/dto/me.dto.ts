import { ApiProperty } from '@nestjs/swagger';

export class MeDto {
  @ApiProperty({ description: 'User ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'Email', example: 'test@example.com' })
  email: string;

  @ApiProperty({ description: 'System admin', example: true })
  systemAdmin: boolean;

  @ApiProperty({ description: 'PIN changed', example: false })
  isPinChanged: boolean;

  @ApiProperty({ description: 'User role', example: 'admin' })
  role?: string;
}
