import { ArchiveCryptoService } from './archive-crypto.service';

describe('ArchiveCryptoService', () => {
  const svc = new ArchiveCryptoService();
  const passphrase = 'correct horse battery staple';

  it('should round-trip a payload', async () => {
    const plain = Buffer.from(JSON.stringify({ hello: 'world', n: 42 }));
    const file = await svc.encrypt(plain, passphrase);

    expect(file.subarray(0, 8).toString('ascii')).toBe('POSKBK01');

    const out = await svc.decrypt(file, passphrase);
    expect(out.toString()).toBe(plain.toString());
  });

  it('should produce a different ciphertext each time', async () => {
    const plain = Buffer.from('same input');
    const a = await svc.encrypt(plain, passphrase);
    const b = await svc.encrypt(plain, passphrase);
    expect(a.equals(b)).toBe(false);
  });

  it('should reject a wrong passphrase', async () => {
    const file = await svc.encrypt(Buffer.from('secret'), passphrase);
    await expect(svc.decrypt(file, 'totally wrong passphrase')).rejects.toThrow(
      /passphrase|corrupt/i,
    );
  });

  it('should reject a file that is not a backup archive', async () => {
    await expect(svc.decrypt(Buffer.alloc(80), passphrase)).rejects.toThrow(/not a valid/i);
  });
});
