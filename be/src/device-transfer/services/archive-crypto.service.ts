import { Injectable, BadRequestException } from '@nestjs/common';
import { promisify } from 'node:util';
import { randomBytes, scrypt as scryptCb, createCipheriv, createDecipheriv } from 'node:crypto';
import { gzip as gzipCb, gunzip as gunzipCb } from 'node:zlib';
import {
  ARCHIVE_MAGIC,
  GCM_IV_BYTES,
  GCM_TAG_BYTES,
  SCRYPT_COST,
  SCRYPT_KEYLEN,
  SCRYPT_SALT_BYTES,
} from '../device-transfer.constants';

const scrypt = promisify(scryptCb) as (
  password: string | Buffer,
  salt: Buffer,
  keylen: number,
  options: { N: number },
) => Promise<Buffer>;
const gzip = promisify(gzipCb);
const gunzip = promisify(gunzipCb);

/**
 * Turns the plaintext JSON payload into the encrypted `.posbackup` blob and back.
 *
 * File layout: `magic(8) | salt(16) | iv(12) | authTag(16) | ciphertext`
 * where ciphertext = AES-256-GCM( gzip(plaintext) ) and the key is
 * scrypt(passphrase, salt).
 */
@Injectable()
export class ArchiveCryptoService {
  async encrypt(plain: Buffer, passphrase: string): Promise<Buffer> {
    const compressed = await gzip(plain);
    const salt = randomBytes(SCRYPT_SALT_BYTES);
    const key = await scrypt(passphrase, salt, SCRYPT_KEYLEN, { N: SCRYPT_COST });
    const iv = randomBytes(GCM_IV_BYTES);
    const cipher = createCipheriv('aes-256-gcm', key, iv);
    const ciphertext = Buffer.concat([cipher.update(compressed), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([ARCHIVE_MAGIC, salt, iv, tag, ciphertext]);
  }

  async decrypt(file: Buffer, passphrase: string): Promise<Buffer> {
    const headerLen = ARCHIVE_MAGIC.length + SCRYPT_SALT_BYTES + GCM_IV_BYTES + GCM_TAG_BYTES;
    if (file.length <= headerLen || !file.subarray(0, ARCHIVE_MAGIC.length).equals(ARCHIVE_MAGIC)) {
      throw new BadRequestException('This file is not a valid POS backup archive.');
    }

    let offset = ARCHIVE_MAGIC.length;
    const salt = file.subarray(offset, (offset += SCRYPT_SALT_BYTES));
    const iv = file.subarray(offset, (offset += GCM_IV_BYTES));
    const tag = file.subarray(offset, (offset += GCM_TAG_BYTES));
    const ciphertext = file.subarray(offset);

    const key = await scrypt(passphrase, salt, SCRYPT_KEYLEN, { N: SCRYPT_COST });
    const decipher = createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);

    let compressed: Buffer;
    try {
      compressed = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
    } catch {
      throw new BadRequestException('Wrong passphrase, or the backup file is corrupted.');
    }

    try {
      return await gunzip(compressed);
    } catch {
      throw new BadRequestException('The backup archive could not be decompressed.');
    }
  }
}
