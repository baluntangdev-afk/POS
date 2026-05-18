import { User } from '../../users/entities/user.entity';
import { RefundCreatedEventItemDto } from '../dto/refund-created-event-item.dto';

export class RefundCreatedEvent {
  constructor(
    public readonly refundId: number,
    public readonly payload: {
      items: RefundCreatedEventItemDto[];
      causer: User;
    },
  ) {}
}
