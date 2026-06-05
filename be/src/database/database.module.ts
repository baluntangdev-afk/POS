import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '../config/config.module';
import { AppConfigService } from '../config/config.service';
import { entities } from './entities-index';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [AppConfigService],
      useFactory: (configService: AppConfigService) => ({
        type: 'postgres',
        host: configService.postgresHost,
        port: configService.postgresPort,
        username: configService.postgresUser,
        password: configService.postgresPassword,
        database: configService.postgresDb,
        entities,
        synchronize: false,
        logging: configService.isDevelopment,
        migrations: [__dirname + '/../migrations/*{.ts,.js}'],
        migrationsRun: false,
        // On a fresh install / after reboot the backend Windows service may start
        // before PostgreSQL is accepting connections. Retry instead of crashing so
        // the kiosk doesn't show "unable to connect to server" during that window.
        retryAttempts: 30,
        retryDelay: 5000,
      }),
    }),
  ],
})
export class DatabaseModule {}
