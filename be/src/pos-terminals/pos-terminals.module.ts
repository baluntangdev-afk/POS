import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PosTerminal } from './entities/pos-terminal.entity';
import { PosTerminalPaymentMethod } from './entities/pos-terminal-payment-method.entity';
import { PosTerminalsService } from './pos-terminals.service';
import { PosTerminalsController } from './pos-terminals.controller';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PosTerminal, PosTerminalPaymentMethod, User])],
  controllers: [PosTerminalsController],
  providers: [PosTerminalsService],
  exports: [PosTerminalsService],
})
export class PosTerminalsModule {}
