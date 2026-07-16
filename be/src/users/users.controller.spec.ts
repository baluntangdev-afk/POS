import { Test, TestingModule } from '@nestjs/testing';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

describe('UsersController', () => {
  let controller: UsersController;
  let service: { findLoginRoster: jest.Mock };

  beforeEach(async () => {
    service = { findLoginRoster: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [{ provide: UsersService, useValue: service }],
    }).compile();

    controller = module.get<UsersController>(UsersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('findLoginRoster', () => {
    it('delegates to usersService.findLoginRoster', async () => {
      const roster = [{ id: 1, userId: 'USR-001', firstName: 'Jane' }];
      service.findLoginRoster.mockResolvedValue(roster);

      const result = await controller.findLoginRoster();

      expect(service.findLoginRoster).toHaveBeenCalled();
      expect(result).toBe(roster);
    });
  });
});
