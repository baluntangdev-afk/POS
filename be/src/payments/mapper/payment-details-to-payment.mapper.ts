import { Payment } from '../entities/payment.entity';
import { PaymentDetailsDto } from '../../sales-orders/dto/confirm-sales-order/payment-details.dto';
import { EntityHelper } from '../../utils/entity.helper';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';

/**
 * Maps payment details DTO (confirm flow) to Payment entity.
 */
export class PaymentDetailsToPaymentMapper {
  /**
   * Maps PaymentDetailsDto to a Payment entity. Set salesOrderId when confirming an order.
   */
  static toEntity(soId: string, dto: PaymentDetailsDto): Payment {
    const payment = new Payment();

    payment.salesOrder = EntityHelper.toIdEntity<SalesOrder>(soId);
    payment.amountPaid = dto.amountPaid;
    payment.change = dto.change;
    payment.paymentMethod = dto.method;
    payment.paymentDate = new Date();
    payment.transactionReference = dto.transactionReference ?? null;

    return payment;
  }
}
