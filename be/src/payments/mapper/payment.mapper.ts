import { Payment } from '../entities/payment.entity';
import { PaymentResponseDto } from '../dto/payment-response.dto';

export class PaymentMapper {
  /**
   * Maps a Payment entity to the API response DTO.
   */
  static toResponse(payment: Payment): PaymentResponseDto {
    return {
      id: payment.id,
      amountPaid: payment.amountPaid,
      change: payment.change,
      paymentMethod: payment.paymentMethod,
      paymentDate: payment.paymentDate,
      transactionReference: payment.transactionReference ?? undefined,
    };
  }
}
