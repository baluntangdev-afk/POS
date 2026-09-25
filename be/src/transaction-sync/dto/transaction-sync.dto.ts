import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class PendingTransactionsQueryDto {
  @ApiProperty({ description: 'Merchant/store id (POS terminal Kiosk ID)', example: 'ABCD2345' })
  @IsString()
  @IsNotEmpty()
  storeId: string;

  @ApiProperty({ required: false, default: 15, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}

export class StoreIdQueryDto {
  @ApiProperty({ description: 'Merchant/store id (POS terminal Kiosk ID)', example: 'ABCD2345' })
  @IsString()
  @IsNotEmpty()
  storeId: string;
}

export class MarkTransactionsSyncedDto {
  @ApiProperty({ type: [String], description: '`accepted_sale_ids` from the orders service' })
  @IsArray()
  @ArrayMaxSize(1000)
  @IsUUID('all', { each: true })
  saleIds: string[];

  @ApiProperty({ type: [Number], description: '`accepted_refund_ids` from the orders service' })
  @IsArray()
  @ArrayMaxSize(1000)
  @IsInt({ each: true })
  refundIds: number[];
}

export class TransferTransactionsDto {
  @ApiProperty({ description: 'The now-active merchant/store id to transfer every sale to' })
  @IsString()
  @IsNotEmpty()
  storeId: string;
}

export class PendingTransactionsDto {
  @ApiProperty({ description: 'Sale records in the orders-service wire format' })
  sales: Record<string, unknown>[];

  @ApiProperty({ description: 'Refund records in the orders-service wire format' })
  refunds: Record<string, unknown>[];
}

export class PendingTransactionCountsDto {
  @ApiProperty()
  sales: number;

  @ApiProperty()
  refunds: number;
}

export class HasTransactionsDto {
  @ApiProperty()
  hasTransactions: boolean;
}
