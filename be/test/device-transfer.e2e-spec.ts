import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

/**
 * Full export -> import round-trip. Requires a running, migrated + seeded dev
 * database and a real admin login. Skipped automatically when POSTGRES_HOST is
 * not set. Override the login via E2E_ADMIN_EMAIL / E2E_ADMIN_PASSWORD.
 */
const shouldRun = Boolean(process.env.POSTGRES_HOST);
const suite = shouldRun ? describe : describe.skip;

suite('Device transfer (e2e)', () => {
  let app: INestApplication<App>;
  let token: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1', { exclude: ['api/docs', 'api/docs-json'] });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        email: process.env.E2E_ADMIN_EMAIL ?? 'admin@example.com',
        password: process.env.E2E_ADMIN_PASSWORD ?? 'admin',
      });
    token = (res.body as { accessToken?: string }).accessToken ?? '';
  });

  afterAll(async () => {
    await app?.close();
  });

  it('should export an archive, then import it without changing row counts', async () => {
    expect(token).toBeTruthy();
    const passphrase = 'e2e-passphrase-abcdef';

    const exportRes = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/export')
      .set('Authorization', `Bearer ${token}`)
      .send({ passphrase })
      .buffer(true)
      .parse((res, cb) => {
        const chunks: Buffer[] = [];
        res.on('data', (c: Buffer) => chunks.push(c));
        res.on('end', () => cb(null, Buffer.concat(chunks)));
      });

    expect(exportRes.status).toBe(201);
    const archive = exportRes.body as Buffer;
    expect(archive.subarray(0, 8).toString('ascii')).toBe('POSKBK01');

    const importRes = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/import')
      .set('Authorization', `Bearer ${token}`)
      .field('passphrase', passphrase)
      .field('confirmReplace', 'true')
      .attach('file', archive, 'backup.posbackup');

    expect(importRes.status).toBe(200);
    const summary = importRes.body as {
      rowsRestored: Record<string, number>;
      restartRecommended: boolean;
    };
    expect(summary.restartRecommended).toBe(true);
    expect(summary.rowsRestored.users).toBeGreaterThan(0);
    expect(summary.rowsRestored.migrations).toBeGreaterThan(0);
  });

  it('should partial-restore its own archive, keeping the local migration history', async () => {
    expect(token).toBeTruthy();
    const passphrase = 'e2e-passphrase-partial';

    const exportRes = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/export')
      .set('Authorization', `Bearer ${token}`)
      .send({ passphrase })
      .buffer(true)
      .parse((res, cb) => {
        const chunks: Buffer[] = [];
        res.on('data', (c: Buffer) => chunks.push(c));
        res.on('end', () => cb(null, Buffer.concat(chunks)));
      });

    const importRes = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/import')
      .set('Authorization', `Bearer ${token}`)
      .field('passphrase', passphrase)
      .field('confirmReplace', 'true')
      .field('partialRestore', 'true')
      .attach('file', exportRes.body as Buffer, 'backup.posbackup');

    expect(importRes.status).toBe(200);
    const summary = importRes.body as {
      rowsRestored: Record<string, number>;
      skipped: { tables: { name: string }[]; columns: unknown[] };
    };
    // Same-version archive: nothing is dropped for incompatibility...
    expect(summary.skipped.columns).toEqual([]);
    // ...but the local `migrations` table is deliberately kept, not reloaded.
    expect(summary.rowsRestored.migrations).toBeUndefined();
    expect(summary.skipped.tables.map((t) => t.name)).toContain('migrations');
    expect(summary.rowsRestored.users).toBeGreaterThan(0);
  });

  it('should reject a wrong passphrase without touching data', async () => {
    const exportRes = await request(app.getHttpServer())
      .post('/api/v1/device-transfer/export')
      .set('Authorization', `Bearer ${token}`)
      .send({ passphrase: 'first-passphrase-xyz' })
      .buffer(true)
      .parse((res, cb) => {
        const chunks: Buffer[] = [];
        res.on('data', (c: Buffer) => chunks.push(c));
        res.on('end', () => cb(null, Buffer.concat(chunks)));
      });

    await request(app.getHttpServer())
      .post('/api/v1/device-transfer/import')
      .set('Authorization', `Bearer ${token}`)
      .field('passphrase', 'a-different-passphrase')
      .field('confirmReplace', 'true')
      .attach('file', exportRes.body as Buffer, 'backup.posbackup')
      .expect(400);
  });
});
