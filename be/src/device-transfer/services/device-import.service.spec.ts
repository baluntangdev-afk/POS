import { ConflictException } from '@nestjs/common';
import { DeviceImportService } from './device-import.service';
import { ArchiveCryptoService } from './archive-crypto.service';
import { ARCHIVE_FORMAT_VERSION } from '../device-transfer.constants';

describe('DeviceImportService', () => {
  const crypto = new ArchiveCryptoService();
  const passphrase = 'passphrase-for-tests';

  function makeService(currentMigrations: string[]) {
    const snapshot = {
      getMigrations: jest.fn().mockResolvedValue(currentMigrations),
      listTables: jest.fn().mockResolvedValue([]),
      restore: jest.fn().mockResolvedValue({ counts: {}, skipped: { tables: [], columns: [] } }),
    };
    const queryRunner = {
      connect: jest.fn().mockResolvedValue(undefined),
      startTransaction: jest.fn().mockResolvedValue(undefined),
      commitTransaction: jest.fn().mockResolvedValue(undefined),
      rollbackTransaction: jest.fn().mockResolvedValue(undefined),
      release: jest.fn().mockResolvedValue(undefined),
    };
    const ds = { createQueryRunner: jest.fn().mockReturnValue(queryRunner) };
    const svc = new DeviceImportService(ds as never, snapshot as never, crypto);
    return { svc, snapshot };
  }

  async function archive(manifest: Record<string, unknown>) {
    return crypto.encrypt(Buffer.from(JSON.stringify({ manifest, tables: [] })), passphrase);
  }

  it('should reject a mismatched migration history', async () => {
    const { svc } = makeService(['A', 'B']);
    const file = await archive({
      formatVersion: ARCHIVE_FORMAT_VERSION,
      migrations: ['A'],
    });
    await expect(svc.import(file, passphrase)).rejects.toBeInstanceOf(ConflictException);
  });

  it('should reject an unknown archive format version', async () => {
    const { svc } = makeService(['A']);
    const file = await archive({ formatVersion: 999, migrations: ['A'] });
    await expect(svc.import(file, passphrase)).rejects.toBeInstanceOf(ConflictException);
  });

  it('should reject a corrupted or non-archive file', async () => {
    const { svc } = makeService(['A']);
    await expect(svc.import(Buffer.from('not an archive at all'), passphrase)).rejects.toThrow(
      /not a valid POS backup archive/i,
    );
  });

  describe('partial restore', () => {
    it('allows a mismatched migration history through and restores partially', async () => {
      const { svc, snapshot } = makeService(['A', 'B']);
      const file = await archive({
        formatVersion: ARCHIVE_FORMAT_VERSION,
        migrations: ['A'],
      });

      const summary = await svc.import(file, passphrase, true);

      expect(snapshot.getMigrations).not.toHaveBeenCalled();
      expect(snapshot.restore).toHaveBeenCalledWith(
        expect.anything(),
        expect.anything(),
        { partial: true },
      );
      expect(summary.skipped).toEqual({ tables: [], columns: [] });
    });

    it('still rejects an unknown archive format version', async () => {
      const { svc } = makeService(['A']);
      const file = await archive({ formatVersion: 999, migrations: ['Z'] });
      await expect(svc.import(file, passphrase, true)).rejects.toBeInstanceOf(ConflictException);
    });

    it('surfaces the restore skip report on the summary', async () => {
      const { svc, snapshot } = makeService(['A']);
      snapshot.restore.mockResolvedValue({
        counts: { users: 3 },
        skipped: {
          tables: [{ name: 'loyalty_accounts', reason: 'not present on this device' }],
          columns: [{ table: 'products', column: 'image_url', reason: 'type changed (bytea → text)' }],
        },
      });
      const file = await archive({ formatVersion: ARCHIVE_FORMAT_VERSION, migrations: ['A'] });

      const summary = await svc.import(file, passphrase, true);

      expect(summary.rowsRestored).toEqual({ users: 3 });
      expect(summary.skipped.tables).toHaveLength(1);
      expect(summary.skipped.columns).toHaveLength(1);
    });
  });
});
