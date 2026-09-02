import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';
import { MIN_PASSPHRASE_LENGTH } from '../device-transfer.constants';

export class ImportDeviceDto {
  @ApiProperty({
    minLength: MIN_PASSPHRASE_LENGTH,
    description: 'The passphrase the archive was exported with.',
  })
  @IsString()
  @MinLength(MIN_PASSPHRASE_LENGTH)
  passphrase: string;

  @ApiProperty({
    enum: ['true'],
    description:
      'Must be the string "true". Acknowledges that all existing data on this device will be permanently replaced.',
  })
  @IsIn(['true'])
  confirmReplace: 'true';

  @ApiPropertyOptional({
    enum: ['true', 'false'],
    description:
      'When "true", skip the migration-history compatibility check and import only the ' +
      'tables and columns this device shares with the backup. Anything that does not line ' +
      'up is reported as skipped instead of failing the import.',
  })
  @IsOptional()
  @IsIn(['true', 'false'])
  partialRestore?: 'true' | 'false';
}
