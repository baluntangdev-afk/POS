import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PosTerminal } from './entities/pos-terminal.entity';
import { CreatePosTerminalDto } from './dto/create-pos-terminal.dto';
import { UpdatePosTerminalDto } from './dto/update-pos-terminal.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class PosTerminalsService {
  constructor(
    @InjectRepository(PosTerminal)
    private readonly posTerminalRepository: Repository<PosTerminal>,
  ) {}

  async findAssignedToUser(userId: number): Promise<PosTerminal> {
    const terminal = await this.posTerminalRepository.findOne({
      where: { assignedUser: { id: userId } },
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
      paymentMethod: dto.paymentMethod,
      paymentNumber: dto.paymentNumber ?? null,
      assignedUser: { id: userId },
      createdBy: { id: userId },
    });

    return this.posTerminalRepository.save(terminal);
  }

  async updateForUser(userId: number, dto: UpdatePosTerminalDto): Promise<PosTerminal> {
    const terminal = await this.findAssignedToUser(userId);

    if (dto.legalName !== undefined) terminal.legalName = dto.legalName;
    if (dto.address !== undefined) terminal.address = dto.address;
    if (dto.tinNumber !== undefined) terminal.tinNumber = dto.tinNumber;
    if (dto.paymentMethod !== undefined) terminal.paymentMethod = dto.paymentMethod;
    terminal.paymentNumber = dto.paymentNumber ?? null;
    terminal.updatedBy = { id: userId } as User;

    return this.posTerminalRepository.save(terminal);
  }
}
