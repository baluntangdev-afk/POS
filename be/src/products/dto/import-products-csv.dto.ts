import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional } from 'class-validator';

export class ImportProductsCsvDto {
  @ApiPropertyOptional({
    description:
      '"upsert" (default) adds/updates rows without removing anything else; ' +
      '"replace" makes the file authoritative — anything not in it is soft-deleted.',
    enum: ['upsert', 'replace'],
    default: 'upsert',
  })
  @IsOptional()
  @IsIn(['upsert', 'replace'])
  mode?: 'upsert' | 'replace';
}
