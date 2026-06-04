import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import {
  HealthCheckService,
  HealthCheck,
  MemoryHealthIndicator,
  DiskHealthIndicator,
  HealthIndicatorResult,
} from '@nestjs/terminus';
import { PostgresHealthIndicator } from './indicators/postgres.health';
import { Public } from '../auth/decorators/public.decorator';

const DISK_PATH = process.platform === 'win32' ? 'C:\\' : '/';

// Health endpoints must bypass the global JWT guard so monitoring and the
// installer's readiness probe can reach them without a token (otherwise 401).
@Public()
@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly memory: MemoryHealthIndicator,
    private readonly disk: DiskHealthIndicator,
    private readonly postgres: PostgresHealthIndicator,
  ) {}

  private checkPostgres = async (): Promise<HealthIndicatorResult> => {
    const result: HealthIndicatorResult = await this.postgres.isHealthy('postgres');
    return result;
  };

  @Get()
  @HealthCheck()
  async check() {
    return this.health.check([
      () => this.memory.checkHeap('memory_heap', 150 * 1024 * 1024),
      () => this.memory.checkRSS('memory_rss', 150 * 1024 * 1024),
      () => this.disk.checkStorage('storage', { path: DISK_PATH, thresholdPercent: 0.9 }),
      () => this.checkPostgres(),
    ]);
  }

  @Get('live')
  @HealthCheck()
  async checkLiveness() {
    return this.health.check([() => this.memory.checkHeap('memory_heap', 150 * 1024 * 1024)]);
  }

  @Get('ready')
  @HealthCheck()
  async checkReadiness() {
    return this.health.check([() => this.checkPostgres()]);
  }
}
