import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import {
  PaginatedQueryDto,
  PaginatedResult,
  parseSort,
  buildFilterWhere,
} from '../utils/pagination';
import { USER_LIST_SELECT } from './dto/user-list-item.dto';
import * as bcrypt from 'bcryptjs';
import { UserDetailsService } from '../user-details/user-details.service';
import { EntityHelper } from '../utils/entity.helper';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly userDetailsService: UserDetailsService,
  ) {}

  async create(createUserDto: CreateUserDto, causer: User) {
    // check if user already exists
    const existingUser = await this.userRepository.findOne({
      select: { id: true },
      where: [{ email: createUserDto.email }, { userId: createUserDto.userId }],
    });

    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    const salt = await bcrypt.genSalt();
    const defaultPin = '000000';
    const password = await bcrypt.hash(defaultPin, salt);
    const devicePin = await bcrypt.hash(defaultPin, salt);

    const user = this.userRepository.create({
      ...createUserDto,
      password,
      devicePin,
      salt,
      createdBy: causer,
      updatedBy: causer,
    });

    const savedUser = await this.userRepository.save(user);

    // Create user_details if any detail field is provided
    if (
      createUserDto.phone !== undefined ||
      createUserDto.address !== undefined ||
      createUserDto.gender !== undefined ||
      createUserDto.dateOfBirth !== undefined
    ) {
      await this.userDetailsService.upsertByUserId(
        savedUser.id,
        {
          phone: createUserDto.phone,
          address: createUserDto.address,
          gender: createUserDto.gender,
          dateOfBirth: createUserDto.dateOfBirth,
        },
        causer,
      );
    }

    return this.findOne(savedUser.id);
  }

  async findAll(query: PaginatedQueryDto): Promise<PaginatedResult<User>> {
    const { page, limit, sort, filter } = query;
    const skip = (page - 1) * limit;

    const USER_SORTABLE_FIELDS: (keyof User)[] = [
      'id',
      'userId',
      'email',
      'firstName',
      'lastName',
      'createdAt',
    ];
    const order = parseSort<User>(sort, {
      allowedFields: USER_SORTABLE_FIELDS,
      defaultOrder: { createdAt: 'DESC' },
    });

    const USER_FILTERABLE_FIELDS: (keyof User)[] = ['email', 'userId', 'firstName', 'lastName'];
    const where = buildFilterWhere<User>(filter, USER_FILTERABLE_FIELDS);

    const [data, total] = await this.userRepository.findAndCount({
      where,
      order,
      take: limit,
      skip,
      select: USER_LIST_SELECT,
    });

    return { data, total, page, limit };
  }

  async findOne(id: number) {
    const user = await this.userRepository.findOne({
      where: { id },
      select: USER_LIST_SELECT,
      relations: ['userDetails'],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async findByEmail(email: string, includePassword = false): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email },
      select: {
        id: true,
        email: true,
        systemAdmin: true,
        isPinChanged: true,
        ...(includePassword && { password: true }),
      },
    });
  }

  async findByUserId(userId: string, includePassword = false): Promise<User | null> {
    return this.userRepository.findOne({
      where: { userId },
      select: {
        id: true,
        email: true,
        systemAdmin: true,
        isPinChanged: true,
        ...(includePassword && { password: true, devicePin: true }),
      },
    });
  }

  async update(id: number, updateUserDto: UpdateUserDto) {
    const payload = this.userRepository.create(updateUserDto);

    if (payload.password) {
      const salt = await bcrypt.genSalt();
      payload.password = await bcrypt.hash(payload.password, salt);
      payload.salt = salt;
    }

    if (payload.devicePin) {
      const salt = await bcrypt.genSalt();
      payload.devicePin = await bcrypt.hash(payload.devicePin, salt);
      payload.salt = salt;
      payload.isPinChanged = true;
      if (updateUserDto.isPinChanged !== undefined && updateUserDto.isPinChanged !== null)
        payload.isPinChanged = updateUserDto.isPinChanged;
    }

    // Create user_details if any detail field is provided
    if (
      updateUserDto.phone !== undefined ||
      updateUserDto.address !== undefined ||
      updateUserDto.gender !== undefined ||
      updateUserDto.dateOfBirth !== undefined
    ) {
      await this.userDetailsService.upsertByUserId(
        id,
        {
          phone: updateUserDto.phone,
          address: updateUserDto.address,
          gender: updateUserDto.gender,
          dateOfBirth: updateUserDto.dateOfBirth,
        },
        updateUserDto.updatedBy!,
      );
    }

    await this.userRepository.update(id, EntityHelper.toPartialEntity(payload));

    return this.findOne(id);
  }

  async remove(id: number) {
    await this.userRepository.softDelete({ id });

    return { message: 'User deleted successfully' };
  }
}
