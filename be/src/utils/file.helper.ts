import * as fs from 'fs';
import * as path from 'path';
import { getAppRoot } from './path.helper';

const SETTINGS_FILENAME = 'settings.txt';
const SETTINGS_KEY = 'kiosk.no';
const ENV_KIOSK_NO = 'KIOSK_NO';

/**
 * Reads kiosk number from the environment or from the POSApp settings file.
 * - Development: from .env (KIOSK_NO).
 * - Production (POSBackend.exe): from POSApp/settings.txt, line "kiosk.no={no}".
 *
 * @returns The kiosk number string, or undefined if not set or file missing.
 */
export function getKioskNo(): string {
  if (process.env.NODE_ENV !== 'production') {
    if (!process.env[ENV_KIOSK_NO]) {
      throw new Error('KIOSK_NO is not set in the environment');
    }
    return process.env[ENV_KIOSK_NO]!;
  }

  const appRoot = getAppRoot();
  const settingsPath = path.join(appRoot, SETTINGS_FILENAME);

  if (!fs.existsSync(settingsPath)) {
    throw new Error(`Settings file not found: ${settingsPath}`);
  }

  const content = fs.readFileSync(settingsPath, 'utf-8');
  const line = content
    .split(/\r?\n/)
    .map((l) => l.trim())
    .find((l) => l.toLowerCase().startsWith(`${SETTINGS_KEY}=`));

  if (!line) {
    throw new Error(`Settings key not found: ${SETTINGS_KEY}`);
  }

  const value = line.slice(SETTINGS_KEY.length + 1).trim();
  if (!value) {
    throw new Error(`Settings value is empty: ${SETTINGS_KEY}`);
  }
  return value;
}
