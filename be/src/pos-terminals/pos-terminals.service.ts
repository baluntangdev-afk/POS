import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PosTerminal } from './entities/pos-terminal.entity';
import { PosTerminalPaymentMethod } from './entities/pos-terminal-payment-method.entity';
import { CreatePosTerminalDto } from './dto/create-pos-terminal.dto';
import { UpdatePosTerminalDto } from './dto/update-pos-terminal.dto';
import { AddPaymentMethodDto } from './dto/add-payment-method.dto';
import { UpdatePaymentMethodDto } from './dto/update-payment-method.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class PosTerminalsService {
  constructor(
    @InjectRepository(PosTerminal)
    private readonly posTerminalRepository: Repository<PosTerminal>,
    @InjectRepository(PosTerminalPaymentMethod)
    private readonly paymentMethodRepository: Repository<PosTerminalPaymentMethod>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async findAssignedToUser(userId: number): Promise<PosTerminal> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: ['posTerminal'],
    });

    if (user?.posTerminal) {
      return this.posTerminalRepository.findOne({
        where: { id: user.posTerminal.id },
        relations: ['paymentMethods'],
      }) as Promise<PosTerminal>;
    }

    const terminal = await this.posTerminalRepository.findOne({
      where: { assignedUser: { id: userId } },
      relations: ['paymentMethods'],
    });

    if (!terminal) {
      throw new NotFoundException('No POS terminal is assigned to your account.');
    }

    return terminal;
  }

  async registerForUser(userId: number, dto: CreatePosTerminalDto): Promise<PosTerminal> {
    const existing = await this.posTerminalRepository.findOne({
      where: { assignedUser: { id: userId } },
    });

    if (existing) {
      throw new ConflictException('A POS terminal is already assigned to your account.');
    }

    const terminal = this.posTerminalRepository.create({
      legalName: dto.legalName,
      address: dto.address,
      tinNumber: dto.tinNumber,
      assignedUser: { id: userId },
      createdBy: { id: userId },
    });

    const saved = await this.posTerminalRepository.save(terminal);
    saved.paymentMethods = [];

    await this.userRepository.update(userId, { posTerminal: { id: saved.id } });

    return saved;
  }

  async updateForUser(userId: number, dto: UpdatePosTerminalDto): Promise<PosTerminal> {
    const terminal = await this.findAssignedToUser(userId);

    if (dto.legalName !== undefined) terminal.legalName = dto.legalName;
    if (dto.address !== undefined) terminal.address = dto.address;
    if (dto.tinNumber !== undefined) terminal.tinNumber = dto.tinNumber;
    terminal.updatedBy = { id: userId } as User;

    return this.posTerminalRepository.save(terminal);
  }

  async addPaymentMethod(userId: number, dto: AddPaymentMethodDto): Promise<PosTerminalPaymentMethod> {
    const terminal = await this.findAssignedToUser(userId);

    const entry = this.paymentMethodRepository.create({
      posTerminal: { id: terminal.id },
      paymentMethod: dto.paymentMethod,
      paymentNumber: dto.paymentNumber ?? null,
    });

    return this.paymentMethodRepository.save(entry);
  }

  async updatePaymentMethod(
    userId: number,
    methodId: number,
    dto: UpdatePaymentMethodDto,
  ): Promise<PosTerminalPaymentMethod> {
    const terminal = await this.findAssignedToUser(userId);

    const entry = await this.paymentMethodRepository.findOne({
      where: { id: methodId, posTerminal: { id: terminal.id } },
    });

    if (!entry) {
      throw new NotFoundException('Payment method not found for your terminal.');
    }

    if (dto.paymentMethod !== undefined) entry.paymentMethod = dto.paymentMethod;
    entry.paymentNumber = dto.paymentNumber !== undefined ? (dto.paymentNumber ?? null) : entry.paymentNumber;

    return this.paymentMethodRepository.save(entry);
  }

  async removePaymentMethod(userId: number, methodId: number): Promise<void> {
    const terminal = await this.findAssignedToUser(userId);

    const entry = await this.paymentMethodRepository.findOne({
      where: { id: methodId, posTerminal: { id: terminal.id } },
    });

    if (!entry) {
      throw new NotFoundException('Payment method not found for your terminal.');
    }

    await this.paymentMethodRepository.remove(entry);
  }
}
