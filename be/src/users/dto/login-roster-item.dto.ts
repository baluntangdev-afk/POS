import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserSuffix } from '../users.enum';
import type { FindOptionsSelect } from 'typeorm';
import type { User } from '../entities/user.entity';

/**
 * Minimal, public-safe shape of a user for the kiosk's pre-login staff tile grid.
 * Excludes email, phone, role, and status — anything not needed to render a tile.
 */
export class LoginRosterItemDto {
  @ApiProperty({ description: 'User ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'User identifier', example: 'USR-001' })
  userId: string;

  @ApiProperty({ description: 'First name', example: 'John' })
  firstName: string;

  @ApiPropertyOptional({ description: 'Middle name' })
  middleName: string | null;

  @ApiProperty({ description: 'Last name', example: 'Doe' })
  lastName: string;

  @ApiPropertyOptional({ description: 'Name suffix', enum: UserSuffix })
  suffix: UserSuffix | null;

  @ApiPropertyOptional({ description: 'Profile image URL' })
  image: string | null;
}

/**
 * TypeORM select option for the login roster query (matches LoginRosterItemDto fields).
 */
export const LOGIN_ROSTER_SELECT: FindOptionsSelect<User> = {
  id: true,
  userId: true,
  firstName: true,
  middleName: true,
  lastName: true,
  suffix: true,
  image: true,
};
