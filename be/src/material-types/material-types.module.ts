import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MaterialTypesService } from './material-types.service';
import { MaterialTypesController } from './material-types.controller';
import { MaterialType } from './entities/material-type.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MaterialType])],
  controllers: [MaterialTypesController],
  providers: [MaterialTypesService],
})
export class MaterialTypesModule {}
