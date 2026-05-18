import { User } from '../../users/entities/user.entity';

export class OrderItemRemovedEvent {
  constructor(
    public readonly salesOrderId: string,
    public readonly payload: {
      soItemIds: string[];
      causer: User;
    },
  ) {}
}
