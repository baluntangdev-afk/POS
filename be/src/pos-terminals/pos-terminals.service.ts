import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PosTerminal } from './entities/pos-terminal.entity';
import { CreatePosTerminalDto } from './dto/create-pos-terminal.dto';

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
}
