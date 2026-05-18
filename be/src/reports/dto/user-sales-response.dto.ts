import { ApiProperty } from '@nestjs/swagger';

/**
 * One user row in the user sales report.
 */
export class UserSalesDataItemDto {
  @ApiProperty({ description: 'User id', example: 1 })
  id: number;

  @ApiProperty({ description: 'User full name', example: 'Jane Doe' })
  name: string;

  @ApiProperty({ description: 'Total sales for this user in the period', example: 700 })
  totalSales: number;
}
