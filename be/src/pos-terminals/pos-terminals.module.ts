import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PosTerminal } from './entities/pos-terminal.entity';
import { PosTerminalsService } from './pos-terminals.service';
import { PosTerminalsController } from './pos-terminals.controller';

@Module({
  imports: [TypeOrmModule.forFeature([PosTerminal])],
  controllers: [PosTerminalsController],
  providers: [PosTerminalsService],
  exports: [PosTerminalsService],
})
export class PosTerminalsModule {}
