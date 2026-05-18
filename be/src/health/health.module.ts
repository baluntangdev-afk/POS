import { Module } from '@nestjs/common';
import { TerminusModule, HealthIndicatorService } from '@nestjs/terminus';
import { HealthController } from './health.controller';
import { PostgresHealthIndicator } from './indicators/postgres.health';

@Module({
  imports: [TerminusModule],
  controllers: [HealthController],
  providers: [HealthIndicatorService, PostgresHealthIndicator],
})
export class HealthModule {}
