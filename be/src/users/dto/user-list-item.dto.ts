import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BaseStatus } from '../../utils/shared-enums';
import { UserRole, UserSuffix } from '../users.enum';
import type { FindOptionsSelect } from 'typeorm';
import type { User } from '../entities/user.entity';
import { UserDetailsListItemDto } from '../../user-details/dto/user-details-list-item.dto';

/**
 * Shape of a user when returned in a paginated list (excludes password, salt, devicePin, relations).
 */
export class UserListItemDto {
  @ApiProperty({ description: 'User ID', example: 1 })
  id: number;

  @ApiProperty({ description: 'User identifier', example: 'USR-001' })
  userId: string;

  @ApiProperty({ description: 'Email address', example: 'john.doe@example.com' })
  email: string;

  @ApiProperty({ description: 'First name', example: 'John' })
  firstName: string;

  @ApiPropertyOptional({ description: 'Middle name' })
  middleName: string | null;

  @ApiProperty({ description: 'Last name', example: 'Doe' })
  lastName: string;

  @ApiPropertyOptional({ description: 'Name suffix', enum: UserSuffix })
  suffix: UserSuffix | null;

  @ApiProperty({ description: 'System admin flag', example: false })
  systemAdmin: boolean;

  @ApiProperty({ description: 'User role', enum: UserRole, example: UserRole.USER })
  role: UserRole;

  @ApiPropertyOptional({ description: 'Profile image URL' })
  image: string | null;

  @ApiPropertyOptional({ description: 'Phone number', example: '+1234567890' })
  phone: string | null;

  @ApiProperty({ description: 'Email verified flag', example: false })
  emailVerified: boolean;

  @ApiProperty({ description: 'Phone verified flag', example: false })
  phoneVerified: boolean;

  @ApiProperty({ description: 'Account locked flag', example: false })
  locked: boolean;

  @ApiProperty({ description: 'User status', enum: BaseStatus })
  status: BaseStatus;

  @ApiPropertyOptional({ description: 'Last login timestamp' })
  lastLogin: Date | null;

  @ApiProperty({ description: 'PIN changed flag', example: false })
  isPinChanged: boolean;

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'User details' })
  userDetails: UserDetailsListItemDto;
}

/**
 * TypeORM select option for listing users (matches UserListItemDto fields).
 */
export const USER_LIST_SELECT: FindOptionsSelect<User> = {
  id: true,
  userId: true,
  email: true,
  firstName: true,
  middleName: true,
  lastName: true,
  suffix: true,
  systemAdmin: true,
  role: true,
  image: true,
  phone: true,
  emailVerified: true,
  phoneVerified: true,
  locked: true,
  status: true,
  lastLogin: true,
  createdAt: true,
  isPinChanged: true,
  userDetails: {
    id: true,
    phone: true,
    address: true,
    gender: true,
    dateOfBirth: true,
  },
};
