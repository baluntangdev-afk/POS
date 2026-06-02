import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class VoidSalesOrderDto {
  @ApiProperty({ description: 'Reason for voiding the transaction' })
  @IsString()
  @IsNotEmpty()
  reason: string;

  @ApiProperty({ description: 'Authorizer user ID (must be admin or supervisor)' })
  @IsString()
  @IsNotEmpty()
  authorizer_user_id: string;

  @ApiProperty({ description: 'Authorizer device PIN' })
  @IsString()
  @IsNotEmpty()
  @MinLength(4)
  authorizer_pin: string;
}
