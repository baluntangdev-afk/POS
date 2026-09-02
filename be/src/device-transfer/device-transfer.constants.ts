/**
 * Binary + crypto parameters for the `.posbackup` archive produced by the
 * device-transfer module. Bump ARCHIVE_FORMAT_VERSION whenever the JSON payload
 * shape changes in a way older backends cannot read.
 */
export const ARCHIVE_MAGIC = Buffer.from('POSKBK01', 'ascii'); // 8 bytes
export const ARCHIVE_FORMAT_VERSION = 1;

/** Minimum operator passphrase length enforced on export and import. */
export const MIN_PASSPHRASE_LENGTH = 12;

export const SCRYPT_SALT_BYTES = 16;
export const SCRYPT_KEYLEN = 32;
/** scrypt cost parameter N (2^14). Balances brute-force resistance vs. a ~100ms derive on kiosk hardware. */
export const SCRYPT_COST = 16384;

export const GCM_IV_BYTES = 12;
export const GCM_TAG_BYTES = 16;

/** Upload ceiling for the import archive (memory-stored multipart). */
export const MAX_ARCHIVE_BYTES = 200 * 1024 * 1024;
