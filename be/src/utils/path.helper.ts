import * as path from 'path';

/**
 * Resolves the application root directory (e.g. POSApp when exe is at POSApp/backend/POSbackend.exe).
 * - POS_APP_ROOT env: use this path when set.
 * - Production (NODE_ENV=production): one level up from the executable directory.
 * - Development: process.cwd() (run from repo root or main folder).
 */
export function getAppRoot(): string {
  if (process.env.POS_APP_ROOT) {
    return path.resolve(process.env.POS_APP_ROOT);
  }
  if (process.env.NODE_ENV === 'production') {
    return path.join(path.dirname(process.execPath), '..');
  }
  return process.cwd();
}

/**
 * Resolves the assets directory.
 * - POS_APP_ROOT set or production: app root + "assets" (e.g. POSApp/assets).
 * - Development: project cwd + "src/assets" (e.g. pos-backend/src/assets).
 */
export function getAssetsPath(): string {
  if (process.env.POS_APP_ROOT) {
    return path.join(path.resolve(process.env.POS_APP_ROOT), 'assets');
  }
  if (process.env.NODE_ENV === 'production') {
    return path.join(path.dirname(process.execPath), '..', 'assets');
  }
  return path.join(process.cwd(), 'src', 'assets');
}
