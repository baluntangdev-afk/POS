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
    // Upsert by email. Deliberately exclude password/salt/device_pin from the
    // update set so re-running the seeder (every install AND every
    // recover-services run) never reverts an admin whose credentials were
    // changed after install. Only the structural fields (role, system_admin) are
    // re-asserted, so recovery still self-heals a mis-flagged admin. On a fresh
    // install with no admin row, the INSERT sets the default password/PIN.
    await repo
      .createQueryBuilder()
      .insert()
      .values(users.map((user) => EntityHelper.toPartialEntity(user)))
      .orUpdate(['role', 'system_admin'], ['email'])
      .execute();
  }
}
