import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { join, resolve } from 'node:path';
import { config as loadDotenv } from 'dotenv';
import { AppModule } from './app.module';
import { AppConfigService } from './config/config.service';
import { runExecArgs } from './exec';

/**
 * Load .env into process.env, overriding stale shell values (e.g. ERP_BASE_URL
 * left pointing at a dead port from a previous terminal session).
 * Order: .env first, then .env.local so local wins.
 */
function loadEnvFiles(): void {
  loadDotenv({ path: resolve(process.cwd(), '.env'), override: true });
  loadDotenv({ path: resolve(process.cwd(), '.env.local'), override: true });
}

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

/**
 * Polls PostgreSQL until it accepts connections, then returns.
 *
 * The backend Windows service starts with DependOnService=POSPostgres, but
 * Windows only waits for the service to enter the "Running" state — not for
 * PostgreSQL to finish its own startup and begin accepting TCP connections.
 * Without this check, TypeORM's internal retries keep port 3000 closed for
 * up to 150 seconds, causing the kiosk to show "unable to reach server".
 *
 * By confirming PostgreSQL is ready here, TypeORM connects on its first
 * attempt and app.listen() is called within seconds of this function returning.
 */
async function waitForPostgres(logger: Logger): Promise<void> {
  // pg is a transitive TypeORM dependency — always present in the bundle.
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { Client } = require('pg') as typeof import('pg');

  const host = process.env.POSTGRES_HOST ?? 'localhost';
  const port = parseInt(process.env.POSTGRES_PORT ?? '5432', 10);
  const user = process.env.POSTGRES_USER ?? 'postgres';
  const password = process.env.POSTGRES_PASSWORD ?? 'postgres';
  const maxAttempts = 60; // 2-minute ceiling (60 × 2 s)

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const client = new Client({
      host,
      port,
      user,
      password,
      database: 'postgres', // maintenance DB — always exists
      connectionTimeoutMillis: 3000,
    });
    try {
      await client.connect();
      await client.end();
      if (attempt > 1) logger.log(`PostgreSQL ready after ${attempt} attempt(s)`);
      return;
    } catch {
      if (attempt === 1 || attempt % 10 === 0) {
        logger.warn(`Waiting for PostgreSQL at ${host}:${port}... (${attempt}/${maxAttempts})`);
      }
      await new Promise<void>((resolve) => setTimeout(resolve, 2000));
    }
  }

  throw new Error(
    `PostgreSQL at ${host}:${port} did not become ready within ${maxAttempts * 2} seconds`,
  );
}

async function bootstrap(): Promise<void> {
  loadEnvFiles();
  loadEnvFromSeaAsset();

  const logger = new Logger('Bootstrap');

  // Wait for PostgreSQL before starting NestJS so TypeORM connects immediately
  // and port 3000 opens as soon as the database is available.
  await waitForPostgres(logger);

  try {
    if (await runExecArgs()) {
      process.exit(0);
    }
  } catch (err) {
    // CLI tasks (--migrate / --seed) own their own logging. Surface only the
    // concise message and exit non-zero — without this, a thrown task error
    // became an unhandled rejection that dumped the full error object/stack.
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(1);
  }

  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });
  const configService = app.get(AppConfigService);
  app.setGlobalPrefix('api/v1', {
    exclude: ['api/docs', 'api/docs-json'],
  });

  // Serve product images and other static assets from the `public/` folder next
  // to the running process (dev: be/public, installed: C:\POSKiosk\backend\public).
  // Reachable at /static/* — outside the api/v1 prefix and the global JWT guard,
  // so the kiosk can load images without auth. Product image_url values point here
  // (e.g. http://localhost:3000/static/products/hot_americano.jpg).
  app.useStaticAssets(join(process.cwd(), 'public'), { prefix: '/static/' });
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
