import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsBoolean, Min, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for creating a refund item.
 */
export class CreateRefundItemDto {
  @ApiProperty({
    description: 'Sales order item ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  @IsNotEmpty()
  @IsUUID(7)
  salesOrderItemId: string;

  @ApiProperty({
    description: 'Quantity to refund',
    example: 2,
  })
  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  @Type(() => Number)
  quantity: number;

  @ApiProperty({
    description: 'Refund amount for this item',
    example: 50.75,
  })
  @IsNotEmpty()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  refundAmount: number;

  @ApiProperty({
    description: 'Whether to restock the inventory',
    example: true,
    default: false,
  })
  @IsBoolean()
  restockInventory?: boolean = false;
}
