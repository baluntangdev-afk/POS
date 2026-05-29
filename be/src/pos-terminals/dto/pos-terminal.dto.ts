import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethodEntryDto } from './payment-method-entry.dto';
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

  @ApiProperty({ type: [PaymentMethodEntryDto] })
  paymentMethods: PaymentMethodEntryDto[];

  static from(terminal: PosTerminal): PosTerminalDto {
    const dto = new PosTerminalDto();
    dto.id = terminal.id;
    dto.kioskId = terminal.kioskId;
    dto.address = terminal.address;
    dto.legalName = terminal.legalName;
    dto.tinNumber = terminal.tinNumber;
    dto.paymentMethods = (terminal.paymentMethods ?? []).map(PaymentMethodEntryDto.from);
    return dto;
  }
}
