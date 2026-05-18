import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsNotEmpty, IsNumber, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateSalesOrderModifierOptionDto } from './modifier-option.dto';

/**
 * Modifier group for create sales order line. Only id and selected options.
 */
export class CreateSalesOrderModifierGroupDto {
  @ApiProperty({ description: 'Modifier group ID', example: 1 })
  @IsNotEmpty()
  @IsNumber()
  @Type(() => Number)
  id: number;

  @ApiProperty({ type: () => [CreateSalesOrderModifierOptionDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSalesOrderModifierOptionDto)
  modifierOptions: CreateSalesOrderModifierOptionDto[];
}
