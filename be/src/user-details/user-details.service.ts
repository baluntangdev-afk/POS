import { Injectable } from '@nestjs/common';
import { UserDetails } from './entities/user-details.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { DeepPartial, Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';

@Injectable()
export class UserDetailsService {
  constructor(
    @InjectRepository(UserDetails)
    private readonly userDetailsRepository: Repository<UserDetails>,
  ) {}

  async upsertByUserId(userId: number, userDetails: DeepPartial<UserDetails>, causer: User) {
    const existingUserDetails = await this.userDetailsRepository.findOne({
      where: { user: { id: userId } },
      select: { id: true },
    });

    const payload = this.userDetailsRepository.create({
      ...(existingUserDetails ? existingUserDetails : { user: { id: userId } }),
      ...userDetails,
      createdBy: causer,
      updatedBy: causer,
    });

    return this.userDetailsRepository.save(payload);
  }
}
