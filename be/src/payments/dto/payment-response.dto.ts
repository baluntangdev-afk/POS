import { ApiProperty } from '@nestjs/swagger';
import { PaymentMethod } from '../payments.enum';

export class PaymentResponseDto {
  @ApiProperty({
    description: 'Payment ID (UUID v7)',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  id: string;

  @ApiProperty({
    description: 'Amount paid',
    example: '150.50',
  })
  amountPaid: string;

  @ApiProperty({
    description: 'Change given',
    example: '0.00',
  })
  change: string;

  @ApiProperty({
    description: 'Payment method',
    enum: PaymentMethod,
    example: PaymentMethod.CASH,
  })
  paymentMethod: PaymentMethod;

  @ApiProperty({
    description: 'Payment date',
    example: '2026-02-20T10:30:00Z',
  })
  paymentDate: Date;

  @ApiProperty({
    description: 'Transaction reference',
    example: 'TXN-123456',
  })
  transactionReference?: string;

  @ApiProperty({
    description: 'Payment method display name (for Other payments)',
    example: 'Maya',
  })
  paymentMethodName?: string;
}
