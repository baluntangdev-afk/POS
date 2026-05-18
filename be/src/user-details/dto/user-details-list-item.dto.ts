import { ApiPropertyOptional } from '@nestjs/swagger';
import { UserDetailsGender } from '../user-details.enum';

/**
 * Shape of user details when returned in a user list item (subset of UserDetails fields).
 */
export class UserDetailsListItemDto {
  @ApiPropertyOptional({ description: 'User details ID', example: 1 })
  id: number;

  @ApiPropertyOptional({ description: 'Phone number', example: '+1234567890' })
  phone: string | null;

  @ApiPropertyOptional({ description: 'Address', example: '123 Main St, City, Country' })
  address: string | null;

  @ApiPropertyOptional({ description: 'Gender', enum: UserDetailsGender })
  gender: UserDetailsGender | null;

  @ApiPropertyOptional({ description: 'Date of birth (YYYY-MM-DD)' })
  dateOfBirth: Date | null;
}
