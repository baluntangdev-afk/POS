import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Currency } from './entities/currency.entity';
import { Repository } from 'typeorm';

@Injectable()
export class CurrenciesService {
  constructor(
    @InjectRepository(Currency)
    private readonly currenciesRepository: Repository<Currency>,
  ) {}

  async findDefaultCurrency() {
    const defaultCurrency = await this.currenciesRepository.findOne({ where: { isDefault: true } });

    if (!defaultCurrency) {
      throw new NotFoundException('Default currency not found');
    }

    return defaultCurrency;
  }
}
