import { Injectable } from '@nestjs/common';
import { CreateDiscountDto } from './dto/create-discount.dto';
import { UpdateDiscountDto } from './dto/update-discount.dto';
import { User } from '../users/entities/user.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Discount } from './entities/discount.entity';

@Injectable()
export class DiscountsService {
  constructor(
    @InjectRepository(Discount)
    private readonly discountRepository: Repository<Discount>,
  ) {}

  create(createDiscountDto: CreateDiscountDto, causer: User) {
    return 'This action adds a new discount';
  }

  findAll() {
    return `This action returns all discounts`;
  }

  findOne(id: number) {
    return this.discountRepository.findOne({ where: { id } });
  }

  async findByIdsToMap(ids: number[]): Promise<Map<number, Discount>> {
    const discounts = await this.discountRepository.find({ where: { id: In(ids) } });

    return new Map(discounts.map((d) => [d.id, d]));
  }

  update(id: number, updateDiscountDto: UpdateDiscountDto) {
    return `This action updates a #${id} discount`;
  }

  remove(id: number, causer: User) {
    return `This action removes a #${id} discount`;
  }
}
