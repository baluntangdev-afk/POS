import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { PosTerminalsService } from './pos-terminals.service';
import { PosTerminal } from './entities/pos-terminal.entity';
import { PosTerminalPaymentMethod } from './entities/pos-terminal-payment-method.entity';
import { User } from '../users/entities/user.entity';

const mockTerminalRepo = {
  findOne: jest.fn(),
  find: jest.fn(),
};

const mockPaymentMethodRepo = {
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  remove: jest.fn(),
};

const mockUserRepo = {
  findOne: jest.fn(),
  update: jest.fn(),
};

describe('PosTerminalsService', () => {
  let service: PosTerminalsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PosTerminalsService,
        { provide: getRepositoryToken(PosTerminal), useValue: mockTerminalRepo },
        { provide: getRepositoryToken(PosTerminalPaymentMethod), useValue: mockPaymentMethodRepo },
        { provide: getRepositoryToken(User), useValue: mockUserRepo },
      ],
    }).compile();

    service = module.get<PosTerminalsService>(PosTerminalsService);
  });

  describe('findAssignedToUser', () => {
    it('returns the terminal directly assigned to the user via user.posTerminal', async () => {
      mockUserRepo.findOne.mockResolvedValue({ id: 5, posTerminal: { id: 10 } });
      const terminal = { id: 10 };
      mockTerminalRepo.findOne.mockResolvedValue(terminal);

      const result = await service.findAssignedToUser(5);

      expect(result).toBe(terminal);
      expect(mockTerminalRepo.findOne).toHaveBeenCalledWith({
        where: { id: 10 },
        relations: ['paymentMethods'],
      });
    });

    it('returns the terminal the user registered when user.posTerminal is unset', async () => {
      mockUserRepo.findOne.mockResolvedValue({ id: 5, posTerminal: null });
      const terminal = { id: 20 };
      mockTerminalRepo.findOne.mockResolvedValueOnce(terminal);

      const result = await service.findAssignedToUser(5);

      expect(result).toBe(terminal);
      expect(mockTerminalRepo.findOne).toHaveBeenCalledWith({
        where: { assignedUser: { id: 5 } },
        relations: ['paymentMethods'],
      });
    });

    it('falls back to the sole terminal in the system for users created before it existed', async () => {
      mockUserRepo.findOne.mockResolvedValue({ id: 5, posTerminal: null });
      mockTerminalRepo.findOne.mockResolvedValueOnce(null); // no direct assignedUser match
      mockTerminalRepo.find.mockResolvedValueOnce([{ id: 99 }]); // fallback lookup

      const result = await service.findAssignedToUser(5);

      expect(result).toEqual({ id: 99 });
      expect(mockTerminalRepo.find).toHaveBeenCalledWith({
        relations: ['paymentMethods'],
        order: { id: 'ASC' },
        take: 1,
      });
    });

    it('throws NotFoundException when no terminal exists at all', async () => {
      mockUserRepo.findOne.mockResolvedValue({ id: 5, posTerminal: null });
      mockTerminalRepo.findOne.mockResolvedValue(null);
      mockTerminalRepo.find.mockResolvedValue([]);

      await expect(service.findAssignedToUser(5)).rejects.toThrow(NotFoundException);
    });
  });
});
