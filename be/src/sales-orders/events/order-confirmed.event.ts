import { User } from '../../users/entities/user.entity';

export class OrderConfirmedEvent {
  constructor(
    public readonly soId: string,
    public readonly causer: User,
  ) {}
}
