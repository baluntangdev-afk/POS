import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AppConfigService } from './config/config.service';
import { runExecArgs } from './exec';

/**
 * Load .env from SEA asset into process.env when running inside a Single Executable Application.
 * See: https://nodejs.org/api/single-executable-applications.html#assets
 */
function loadEnvFromSeaAsset(): void {
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const sea = require('node:sea');
    if (typeof sea.isSea === 'function' && sea.isSea()) {
      const envContent = sea.getAsset('env', 'utf8') as string;
      const lines = envContent.split(/\r?\n/);
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed === '' || trimmed.startsWith('#')) continue;
        const eq = trimmed.indexOf('=');
        if (eq === -1) continue;
        const key = trimmed.slice(0, eq).trim();
        const value = trimmed.slice(eq + 1).trim();
        if (key && typeof process.env[key] === 'undefined') {
          process.env[key] = value.replace(/^["']|["']$/g, '');
        }
      }
    }
  } catch {
    // Not running in SEA or no 'env' asset; .env will be loaded from filesystem by ConfigModule
  }
}

async function bootstrap(): Promise<void> {
  loadEnvFromSeaAsset();

  if (await runExecArgs()) {
    process.exit(0);
  }

  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });
  const configService = app.get(AppConfigService);
  app.setGlobalPrefix('api/v1', {
    exclude: ['api/docs', 'api/docs-json'],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
    }),
  );

  if (configService.isDevelopment) {
    const config = new DocumentBuilder()
      .setTitle('POS Backend API')
      .setDescription('POS Backend API Documentation')
      .setVersion('1.0')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
    logger.log(
      `Swagger documentation available at: http://localhost:${configService.port}/api/docs`,
    );
  }

  const port = configService.port;
  await app.listen(port);
  logger.log(`Application is running on: http://localhost:${port}`);
  logger.log(`Environment: ${configService.nodeEnv}`);
}

void bootstrap();
