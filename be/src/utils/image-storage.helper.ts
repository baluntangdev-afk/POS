import * as fs from 'fs';
import * as path from 'path';
import { File } from 'multer';
import { Request } from 'express';

/**
 * Derives the scheme+host the current request actually came in on
 * (e.g. http://localhost:3000), so generated URLs work whether the
 * backend is reached via localhost or a LAN address.
 */
export function getBaseUrl(req: Request): string {
  return `${req.protocol}://${req.get('host')}`;
}

/**
 * Saves an uploaded image under public/<subDir>/ and returns its absolute
 * /static/ URL, prefixed with the given base URL (the host the request
 * actually came in on, e.g. http://localhost:3000). An absolute URL is
 * required because the kiosk's Image.network/CachedNetworkImage widgets
 * can't resolve a bare relative path.
 * Filename is a millisecond timestamp (Date.now()) with the uploaded file's
 * original extension, so the DB stores a short URL instead of the raw file
 * (previously saved as a base64 string directly in image_url).
 */
export function saveUploadedImage(image: File, subDir: string, baseUrl: string): string {
  const ext = path.extname(image.originalname);
  const filename = `${Date.now()}${ext}`;
  const dir = path.join(process.cwd(), 'public', subDir);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, filename), image.buffer);
  return `${baseUrl}/static/${subDir}/${filename}`;
}
