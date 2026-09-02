import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';
import { MIN_PASSPHRASE_LENGTH } from '../device-transfer.constants';

export class ExportDeviceDto {
  @ApiProperty({
    minLength: MIN_PASSPHRASE_LENGTH,
    description:
      'Passphrase used to encrypt the archive. The same passphrase is required to import it.',
  })
  @IsString()
  @MinLength(MIN_PASSPHRASE_LENGTH)
  passphrase: string;
}
