import { Injectable } from '@nestjs/common';
import { HealthIndicatorService, HealthIndicatorResult } from '@nestjs/terminus';
import { ConfigService } from '@nestjs/config';
import { Client } from 'pg';

@Injectable()
export class PostgresHealthIndicator {
  constructor(
    private readonly configService: ConfigService,
    private readonly healthIndicatorService: HealthIndicatorService,
  ) {}

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    const host = this.configService.get<string>('POSTGRES_HOST', 'localhost');
    const port = this.configService.get<number>('POSTGRES_PORT', 5432);
    const user = this.configService.get<string>('POSTGRES_USER', 'postgres');
    const password = this.configService.get<string>('POSTGRES_PASSWORD', 'postgres');
    const database = this.configService.get<string>('POSTGRES_DB', 'pos_db');

    const client = new Client({
      host,
      port,
      user,
      password,
      database,
      connectionTimeoutMillis: 5000,
    });

    const indicator = this.healthIndicatorService.check(key);

    try {
      await client.connect();
      await client.query('SELECT 1');
      await client.end();
      return indicator.up({ message: 'PostgreSQL is healthy' });
    } catch (error) {
      await client.end().catch(() => {});
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return indicator.down({ message: errorMessage });
    }
  }
}
