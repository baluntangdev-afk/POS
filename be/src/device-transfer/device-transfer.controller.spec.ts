import { BadRequestException } from '@nestjs/common';
import { DeviceTransferController } from './device-transfer.controller';

describe('DeviceTransferController', () => {
  const exportService = { export: jest.fn() };
  const importService = { import: jest.fn() };
  const controller = new DeviceTransferController(exportService as never, importService as never);

  afterEach(() => jest.clearAllMocks());

  it('should reject an import with no file', async () => {
    await expect(
      controller.import(undefined, {
        passphrase: 'x'.repeat(12),
        confirmReplace: 'true',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(importService.import).not.toHaveBeenCalled();
  });

  it('should set attachment headers and return the archive on export', async () => {
    exportService.export.mockResolvedValue({
      buffer: Buffer.from('archive-bytes'),
      manifest: {
        createdAt: '2026-09-02T10:00:00.000Z',
        tableRowCounts: { users: 2 },
      },
    });
    const res = { set: jest.fn() };

    const result = await controller.export({ passphrase: 'x'.repeat(12) }, res as never);

    expect(res.set).toHaveBeenCalledWith(
      expect.objectContaining({
        'Content-Type': 'application/octet-stream',
        'Content-Disposition':
          'attachment; filename="pos-kiosk-backup-2026-09-02-10-00-00.posbackup"',
      }),
    );
    expect(result.getStream).toBeDefined();
  });

  it('should pass the uploaded buffer through to the import service', async () => {
    importService.import.mockResolvedValue({ rowsRestored: {} });
    const file = { buffer: Buffer.from('data') };

    await controller.import(file as never, {
      passphrase: 'y'.repeat(12),
      confirmReplace: 'true',
    });

    expect(importService.import).toHaveBeenCalledWith(file.buffer, 'y'.repeat(12), false);
  });

  it('should forward the partial-restore flag to the import service', async () => {
    importService.import.mockResolvedValue({ rowsRestored: {} });
    const file = { buffer: Buffer.from('data') };

    await controller.import(file as never, {
      passphrase: 'y'.repeat(12),
      confirmReplace: 'true',
      partialRestore: 'true',
    });

    expect(importService.import).toHaveBeenCalledWith(file.buffer, 'y'.repeat(12), true);
  });
});
