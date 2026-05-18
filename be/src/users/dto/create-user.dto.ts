import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { BaseStatus } from '../../utils/shared-enums';
import { UserSuffix } from '../users.enum';
import { UserDetailsGender } from '../../user-details/user-details.enum';

const lowerCaseTransformer = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.toLowerCase().trim() : value;

/**
 * DTO for creating a new user.
 */
export class CreateUserDto {
  @ApiProperty({ type: () => String, example: 'john.doe@cody.inc' })
  @Transform(lowerCaseTransformer)
  @IsNotEmpty()
  @IsEmail()
  email: string;

  @ApiProperty({ type: () => String, example: 'john.doe' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(50)
  userId: string;

  @ApiProperty({ type: () => String, example: 'John' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  firstName: string;

  @ApiPropertyOptional({ type: () => String, example: null })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  middleName?: string | null;

  @ApiProperty({ type: () => String, example: 'Doe' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  lastName: string;

  @ApiPropertyOptional({
    type: String,
    description: 'Suffix of the employee name (e.g., Jr., Sr.)',
    enum: UserSuffix,
    example: UserSuffix.JR,
  })
  @IsEnum(UserSuffix, {
    message: 'suffix must be one of: Jr, Sr, II, III, IV, V, or None',
  })
  @IsOptional()
  suffix?: UserSuffix | null;

  @ApiPropertyOptional({
    type: String,
    required: false,
    description: 'Image in base 64 format or URL.',
    example: `https://4.img-dpreview.com/files/p/E~TS590x0~articles/3925134721/0266554465.jpeg`,
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  image?: string | null;

  //   @ApiPropertyOptional({ type: Number, example: 1, nullable: true })
  //   @IsOptional()
  //   @IsInt()
  //   costCenter?: number | null;

  @ApiPropertyOptional({
    type: String,
    enum: BaseStatus,
    description: 'User status',
    example: BaseStatus.ACTIVE,
    default: BaseStatus.ACTIVE,
  })
  @IsOptional()
  @IsEnum(BaseStatus, {
    message: 'status must be a valid status from the enum',
  })
  status?: BaseStatus;

  @ApiPropertyOptional({ type: Boolean, example: false, default: false })
  @IsOptional()
  @IsBoolean()
  systemAdmin?: boolean;

  @ApiPropertyOptional({
    type: String,
    description: 'Phone number',
    example: '+1234567890',
  })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  phone?: string | null;

  @ApiPropertyOptional({
    type: Boolean,
    description: 'Has the user verified their email?',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  emailVerified?: boolean;

  @ApiPropertyOptional({
    type: Boolean,
    description: 'Has the user verified their phone?',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  phoneVerified?: boolean;

  //   @ApiPropertyOptional({
  //     type: Number,
  //     example: 1,
  //     description: 'Preferred currency id for checkout/pricing',
  //   })
  //   @IsOptional()
  //   @IsInt()
  //   preferredCurrencyId?: number | null;

  @ApiPropertyOptional({
    type: String,
    description: 'Address',
    example: '123 Main St, City, Country',
  })
  @IsOptional()
  @IsString()
  address?: string | null;

  @ApiPropertyOptional({
    enum: UserDetailsGender,
    description: 'Gender',
    example: UserDetailsGender.MALE,
  })
  @IsOptional()
  @IsEnum(UserDetailsGender)
  gender?: UserDetailsGender | null;

  @ApiPropertyOptional({
    type: String,
    description: 'Date of birth (YYYY-MM-DD)',
    example: '1990-01-15',
  })
  @IsOptional()
  @IsDateString()
  dateOfBirth?: string | null;

  @ApiPropertyOptional({
    type: String,
    description:
      'Profile picture. Send empty string or null to remove existing picture. ' +
      'For file upload, use multipart/form-data with "avatar" field.',
    example: '',
  })
  @IsOptional()
  @IsString()
  profilePicture?: string | null;

  @ApiPropertyOptional({ type: Boolean, example: false, default: false })
  @IsOptional()
  @IsBoolean()
  locked?: boolean;
}
