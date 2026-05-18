import { DataSource } from 'typeorm';
import { User } from '../users/entities/user.entity';

export class SeederHelper {
  constructor(private readonly dataSource: DataSource) {}
  async getAdminUser(): Promise<User> {
    const user = await this.dataSource
      .getRepository(User)
      .findOne({ where: { systemAdmin: true }, select: { id: true } });

    if (!user) {
      throw new Error('Admin user not found');
    }

    return user;
  }
}
