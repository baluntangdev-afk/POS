import { Injectable } from '@nestjs/common';
import { ConfigService as NestConfigService } from '@nestjs/config';

@Injectable()
export class AppConfigService {
  constructor(private readonly configService: NestConfigService) {}

  get port(): number {
    return this.configService.get<number>('PORT', 3000);
  }

  get nodeEnv(): string {
    return this.configService.get<string>('NODE_ENV', 'development');
  }

  get isDevelopment(): boolean {
    return this.nodeEnv === 'development';
  }

  get isProduction(): boolean {
    return this.nodeEnv === 'production';
  }

  get postgresHost(): string {
    return this.configService.get<string>('POSTGRES_HOST', 'localhost');
  }

  get postgresPort(): number {
    return this.configService.get<number>('POSTGRES_PORT', 5432);
  }

  get postgresUser(): string {
    return this.configService.get<string>('POSTGRES_USER', 'postgres');
  }

  get postgresPassword(): string {
    return this.configService.get<string>('POSTGRES_PASSWORD', 'postgres');
  }

  get postgresDb(): string {
    return this.configService.get<string>('POSTGRES_DB', 'pos_db');
  }

  get jwtSecret(): string {
    return this.configService.get<string>('JWT_SECRET', 'change-me-in-production');
  }

  get jwtExpiresIn(): string {
    return this.configService.get<string>('JWT_EXPIRES_IN', '15m');
  }

  get jwtRefreshSecret(): string {
    return this.configService.get<string>('JWT_REFRESH_SECRET', 'change-me-refresh-in-production');
  }

  get jwtRefreshExpiresIn(): string {
    return this.configService.get<string>('JWT_REFRESH_EXPIRES_IN', '7d');
  }
}
