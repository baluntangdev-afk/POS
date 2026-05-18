import { Module } from '@nestjs/common';
import { TerminusModule, HealthIndicatorService } from '@nestjs/terminus';
import { HttpModule } from '@nestjs/axios';
import { HealthController } from './health.controller';
import { PostgresHealthIndicator } from './indicators/postgres.health';

@Module({
  imports: [TerminusModule, HttpModule],
  controllers: [HealthController],
  providers: [HealthIndicatorService, PostgresHealthIndicator],
})
export class HealthModule {}
