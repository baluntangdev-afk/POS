import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';
import type { PosTerminalPaymentMethod } from '../entities/pos-terminal-payment-method.entity';

export class PaymentMethodEntryDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ enum: PaymentMethod })
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({ example: '09171234567' })
  paymentNumber: string | null;

  static from(entry: PosTerminalPaymentMethod): PaymentMethodEntryDto {
    const dto = new PaymentMethodEntryDto();
    dto.id = entry.id;
    dto.paymentMethod = entry.paymentMethod;
    dto.paymentNumber = entry.paymentNumber;
    return dto;
  }
}
