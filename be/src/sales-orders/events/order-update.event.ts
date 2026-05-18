import { User } from '../../users/entities/user.entity';
import { OrderCreatedEventItemDto } from '../dto/order-created-event-item.dto';

export class OrderUpdatedEvent {
  constructor(
    public readonly salesOrderId: string,
    public readonly payload: {
      items: OrderCreatedEventItemDto[];
      oldSoItemIds: string[];
      causer: User;
    },
  ) {}
}
