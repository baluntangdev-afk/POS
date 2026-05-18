import { Module } from '@nestjs/common';
import { UomService } from './uom.service';
import { UomController } from './uom.controller';

@Module({
  controllers: [UomController],
  providers: [UomService],
})
export class UomModule {}
