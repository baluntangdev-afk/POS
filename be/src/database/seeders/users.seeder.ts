import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { User } from '../../users/entities/user.entity';
import { UserRole } from '../../users/users.enum';
import { BaseStatus } from '../../utils/shared-enums';
import bcrypt from 'bcryptjs';
import { EntityHelper } from '../../utils/entity.helper';

/**
 * Seeder: UsersSeeder
 */
export class UsersSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const salt = await bcrypt.genSalt();
    const password = await bcrypt.hash('password', salt);

    const users: Partial<User>[] = [
      {
        userId: 'admin',
        email: 'admin@cody.inc',
        password,
        salt,
        firstName: 'Cody',
        lastName: 'Admin',
        devicePin: await bcrypt.hash('123456', salt),
        status: BaseStatus.ACTIVE,
        systemAdmin: true,
        role: UserRole.ADMIN,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ];

    const repo = dataSource.getRepository(User);
    await repo
      .createQueryBuilder()
      .insert()
      .values(users.map((user) => EntityHelper.toPartialEntity(user)))
      .orUpdate(['password', 'salt', 'device_pin', 'role', 'system_admin'], ['email'])
      .execute();
  }
}
