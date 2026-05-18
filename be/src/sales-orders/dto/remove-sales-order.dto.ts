import { ApiProperty } from '@nestjs/swagger';
import { User } from '../../users/entities/user.entity';

export class RemoveSalesOrderItemDto {
  @ApiProperty({
    description: 'Sales order ID',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  id: string;

  @ApiProperty({
    description: 'Sales order item ID',
    example: '01936b3a-1234-7000-8000-000000000000',
  })
  soItemId: string;

  @ApiProperty({
    description: 'User who deleted the sales order item',
  })
  deletedBy: User;
}
