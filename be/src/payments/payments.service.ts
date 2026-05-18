import { Injectable } from '@nestjs/common';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { UpdatePaymentDto } from './dto/update-payment.dto';
import { User } from '../users/entities/user.entity';
import { PaymentQueryDto } from './dto/payment-query.dto';
import { PaymentResponseDto } from './dto/payment-response.dto';
import { Payment } from './entities/payment.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, FindOptionsWhere } from 'typeorm';
import { PaginatedResult, parseSort } from '../utils/pagination';
import dayjs from 'dayjs';
import { PaymentMapper } from './mapper/payment.mapper';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
  ) {}

  create(createPaymentDto: CreatePaymentDto, causer: User) {
    return 'This action adds a new payment';
  }

  async findAll(query: PaymentQueryDto): Promise<PaginatedResult<PaymentResponseDto>> {
    const { page, limit, sort, paymentMethod, paymentDate, transactionReference, soNumber } = query;
    const skip = (page - 1) * limit;

    const PAYMENT_SORTABLE_FIELDS: (keyof Payment)[] = [
      'id',
      'paymentMethod',
      'paymentDate',
      'transactionReference',
    ];
    const order = parseSort<Payment>(sort, {
      allowedFields: PAYMENT_SORTABLE_FIELDS,
      defaultOrder: { paymentDate: 'DESC' },
    });

    const where: FindOptionsWhere<Payment> = {};

    if (paymentMethod) {
      where.paymentMethod = paymentMethod;
    }

    if (paymentDate) {
      const startDate = dayjs(paymentDate).startOf('day').toDate();
      const endDate = dayjs(paymentDate).endOf('day').toDate();
      where.paymentDate = Between(startDate, endDate);
    }

    if (transactionReference) {
      where.transactionReference = transactionReference;
    }

    if (soNumber) {
      where.salesOrder = { soNumber };
    }

    const [payments, total] = await this.paymentRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      relations: {
        salesOrder: true,
      },
    });

    const data = payments.map(PaymentMapper.toResponse);

    return { data, total, page, limit };
  }

  findOne(id: string) {
    return `This action returns a #${id} payment`;
  }

  update(id: string, updatePaymentDto: UpdatePaymentDto) {
    return `This action updates a #${id} payment`;
  }

  remove(id: string, causer: User) {
    return `This action removes a #${id} payment`;
  }
}
