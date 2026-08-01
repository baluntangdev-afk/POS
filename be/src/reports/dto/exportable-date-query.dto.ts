import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class ExportableDateQueryDto {
  @ApiProperty({ description: 'Date to check (YYYY-MM-DD)', example: '2026-06-02' })
  @IsDateString()
  date: string;
}
