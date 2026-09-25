'use strict';

// Wipes the Flutter kiosk app's local state so the next launch behaves like a
// fresh install (onboarding + device registration). Windows only.
//   - %APPDATA%\inc.cody\pos_app          secure storage + shared preferences
//   - %USERPROFILE%\Documents\kiosk_pos.* Drift local database
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

if (process.platform !== 'win32') {
  console.error('kiosk-reset only supports Windows.');
  process.exit(1);
}

try {
  execSync('taskkill /IM pos_app.exe /F', { stdio: 'ignore' });
  console.log('Stopped running pos_app.exe');
} catch {
  // not running
}

const appSupportDir = path.join(process.env.APPDATA, 'inc.cody', 'pos_app');
const documentsDir = path.join(os.homedir(), 'Documents');

const targets = [
  appSupportDir,
  ...fs
    .readdirSync(documentsDir)
    .filter((f) => f.startsWith('kiosk_pos.sqlite'))
    .map((f) => path.join(documentsDir, f)),
];

for (const target of targets) {
  if (!fs.existsSync(target)) continue;
  try {
    // taskkill returns before the process releases its file handles, so retry
    // on EPERM/EBUSY for a few seconds instead of failing immediately.
    fs.rmSync(target, { recursive: true, force: true, maxRetries: 10, retryDelay: 300 });
    console.log(`Removed ${target}`);
  } catch (err) {
    console.error(`Could not remove ${target} (${err.code}). Close anything using it and re-run.`);
    process.exit(1);
  }
}

console.log('Kiosk app state cleared.');
