import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../payments/payments.enum';
import type { PosTerminal } from '../entities/pos-terminal.entity';

export class PosTerminalDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: '018f2c3d-...' })
  kioskId: string;

  @ApiProperty({ example: '123 Main St.' })
  address: string;

  @ApiPropertyOptional({ example: 'ABC Corporation' })
  legalName: string | null;

  @ApiProperty({ example: '123-456-789-000' })
  tinNumber: string;

  @ApiProperty({ enum: PaymentMethod })
  paymentMethod: PaymentMethod;

  @ApiPropertyOptional({ example: '09171234567' })
  paymentNumber: string | null;

  static from(terminal: PosTerminal): PosTerminalDto {
    const dto = new PosTerminalDto();
    dto.id = terminal.id;
    dto.kioskId = terminal.kioskId;
    dto.address = terminal.address;
    dto.legalName = terminal.legalName;
    dto.tinNumber = terminal.tinNumber;
    dto.paymentMethod = terminal.paymentMethod;
    dto.paymentNumber = terminal.paymentNumber;
    return dto;
  }
}
