import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Refund } from '../entities/refund.entity';
import { getKioskNo } from '../../utils/file.helper';
import dayjs from 'dayjs';

@Injectable()
export class RefundNumberGenerationService {
  constructor(
    @InjectRepository(Refund)
    private readonly refundRepository: Repository<Refund>,
  ) {}

  async generateRefundNumber(): Promise<string> {
    const currentYear = dayjs().format('YYYY');
    const kioskNo = getKioskNo();
    const prefix = `REF-${kioskNo.padStart(3, '0')}-${currentYear}`;

    const lastRefundNumber = await this.refundRepository
      .createQueryBuilder('refund')
      .select('refund.refundNumber')
      .where('refund.refundNumber LIKE :prefix', { prefix: `${prefix}%` })
      .orderBy('refund.refundNumber', 'DESC')
      .withDeleted()
      .getOne();

    if (!lastRefundNumber) {
      return `${prefix}-0001`;
    }

    const lastFour = lastRefundNumber.refundNumber.slice(-4);
    const lastRefundNumberInt = parseInt(lastFour, 10);
    const nextRefundNumberInt = lastRefundNumberInt + 1;

    return `${prefix}-${nextRefundNumberInt.toString().padStart(4, '0')}`;
  }
}
