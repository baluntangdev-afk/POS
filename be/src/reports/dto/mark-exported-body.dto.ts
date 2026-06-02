import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class MarkExportedBodyDto {
  @ApiProperty({ description: 'Date to mark as exported (YYYY-MM-DD)', example: '2026-06-02' })
  @IsDateString()
  date: string;
}
