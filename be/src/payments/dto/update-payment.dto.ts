import { PartialType } from '@nestjs/swagger';
import { CreatePaymentDto } from './create-payment.dto';

/**
 * DTO for updating a payment (all fields optional).
 */
export class UpdatePaymentDto extends PartialType(CreatePaymentDto) {}
