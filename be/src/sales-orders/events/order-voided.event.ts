import { User } from '../../users/entities/user.entity';

export class OrderVoidedEvent {
  constructor(
    public readonly soId: string,
    public readonly authorizer: User,
  ) {}
}
