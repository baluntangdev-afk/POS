import { Injectable } from '@nestjs/common';
import { CreateRefundDto } from './dto/create-refund.dto';
import { UpdateRefundDto } from './dto/update-refund.dto';
import { User } from '../users/entities/user.entity';
import { RefundWithItemsResponseDto } from './dto/refund-with-items-response.dto';
import { CreateRefundService } from './services/create-refund.service';
import { RefundQueryDto } from './dto/refund-query.dto';
import { Refund } from './entities/refund.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, FindOptionsWhere } from 'typeorm';
import { PaginatedResult, parseSort } from '../utils/pagination';
import dayjs from 'dayjs';
import { RefundMapper } from './mapper/refund.mapper';

@Injectable()
export class RefundsService {
  constructor(
    private readonly createRefundService: CreateRefundService,
    @InjectRepository(Refund)
    private readonly refundRepository: Repository<Refund>,
  ) {}

  async create(
    createRefundDto: CreateRefundDto,
    causer: User,
  ): Promise<RefundWithItemsResponseDto> {
    return await this.createRefundService.execute(createRefundDto, causer);
  }

  async findAll(query: RefundQueryDto): Promise<PaginatedResult<RefundWithItemsResponseDto>> {
    const {
      page,
      limit,
      sort,
      paymentMethod,
      refundDate,
      transactionReference,
      originalSalesOrderId,
      refundNumber,
    } = query;
    const skip = (page - 1) * limit;

    const REFUND_SORTABLE_FIELDS: (keyof Refund)[] = [
      'id',
      'refundNumber',
      'paymentMethod',
      'refundDate',
      'transactionReference',
      'totalRefundAmount',
    ];
    const order = parseSort<Refund>(sort, {
      allowedFields: REFUND_SORTABLE_FIELDS,
      defaultOrder: { refundDate: 'DESC' },
    });

    const where: FindOptionsWhere<Refund> = {};

    if (paymentMethod) {
      where.paymentMethod = paymentMethod;
    }

    if (refundDate) {
      const startDate = dayjs(refundDate).startOf('day').toDate();
      const endDate = dayjs(refundDate).endOf('day').toDate();
      where.refundDate = Between(startDate, endDate);
    }

    if (transactionReference) {
      where.transactionReference = transactionReference;
    }

    if (originalSalesOrderId) {
      where.originalSalesOrder = { id: originalSalesOrderId };
    }

    if (refundNumber) {
      where.refundNumber = refundNumber;
    }

    const [refunds, total] = await this.refundRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      relations: {
        originalSalesOrder: true,
        refundItems: {
          salesOrderItem: true,
        },
      },
    });

    const data = refunds.map(RefundMapper.toResponse);

    return { data, total, page, limit };
  }

  findOne(id: number) {
    return `This action returns a #${id} refund`;
  }

  update(id: number, updateRefundDto: UpdateRefundDto) {
    return `This action updates a #${id} refund`;
  }

  remove(id: number, causer: User) {
    return `This action removes a #${id} refund`;
  }
}
