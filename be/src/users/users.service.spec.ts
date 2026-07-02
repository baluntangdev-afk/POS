import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { User } from './entities/user.entity';
import { PosTerminal } from '../pos-terminals/entities/pos-terminal.entity';
import { UserDetailsService } from '../user-details/user-details.service';

const mockUserRepo = {
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  findOne: jest.fn(),
};

const mockPosTerminalRepo = {
  find: jest.fn(),
};

const mockUserDetailsService = {
  upsertByUserId: jest.fn(),
};

const causer = { id: 1 } as User;

describe('UsersService', () => {
  let service: UsersService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: mockUserRepo },
        { provide: getRepositoryToken(PosTerminal), useValue: mockPosTerminalRepo },
        { provide: UserDetailsService, useValue: mockUserDetailsService },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    const dto = { userId: 'jane.doe', firstName: 'Jane', lastName: 'Doe' };

    beforeEach(() => {
      mockUserRepo.create.mockImplementation((data) => data);
      mockUserRepo.save.mockResolvedValue({ id: 42 });
      mockUserRepo.findOne
        .mockResolvedValueOnce(null) // userId conflict check
        .mockResolvedValueOnce({ id: 42 }); // final findOne(savedUser.id)
    });

    it('assigns the newly created user to the deployment POS terminal when one exists', async () => {
      mockPosTerminalRepo.find.mockResolvedValue([{ id: 7 }]);

      await service.create(dto as never, causer);

      expect(mockPosTerminalRepo.find).toHaveBeenCalledWith({
        select: { id: true },
        order: { id: 'ASC' },
        take: 1,
      });
      expect(mockUserRepo.update).toHaveBeenCalledWith(42, { posTerminal: { id: 7 } });
    });

    it('leaves the user unassigned when no POS terminal has been registered yet', async () => {
      mockPosTerminalRepo.find.mockResolvedValue([]);

      await service.create(dto as never, causer);

      expect(mockUserRepo.update).not.toHaveBeenCalled();
    });
  });
});
