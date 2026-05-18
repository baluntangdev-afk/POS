import { execSync } from 'child_process';
import * as fs from 'fs';

// --- CONFIGURATION ---
const MAIN_FILE = 'src/main.ts';
const OUTPUT_DIR = 'dist_sea';
const SEA_CONFIG = 'sea-config.json';
const SEA_PREP_BLOB = 'sea-prep.blob';
// Detect OS to name the output file correctly
const EXE_NAME = 'POSBackend.exe';
// The "Magic String" Node uses to find the injected code
const SENTINEL_FUSE = 'NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2';
// --- UTILS ---
const log = (msg: string) => console.log(`\x1b[36m${msg}\x1b[0m`); // Cyan text
const run = (cmd: string) => {
  try {
    execSync(cmd, { stdio: 'inherit' });
  } catch {
    console.error(`❌ Failed: ${cmd}`);
    process.exit(1);
  }
};

function build() {
  log(`🚀 Starting SEA Build for ${process.platform}...`);
  // 1. Clean previous builds
  if (fs.existsSync(OUTPUT_DIR))
    fs.rmSync(OUTPUT_DIR, {
      recursive: true,
      force: true,
    });
  if (fs.existsSync(EXE_NAME)) fs.unlinkSync(EXE_NAME);
  // 2. Bundle the App (NestJS -> Single JS File)
  log(`📦 Bundling with NCC...`);
  run(`npx ncc build ${MAIN_FILE} -o ${OUTPUT_DIR} -m`);
  // 3. Generate the Blob
  log(`💧 Generating SEA Blob...`);
  run(`node --experimental-sea-config ${SEA_CONFIG}`);
  // 4. Copy the Node Executable
  log(`💿 Copying Node binary...`);
  const nodePath = process.execPath; // Path to the node binary
  // running this script
  fs.copyFileSync(nodePath, EXE_NAME);
  // 5. Remove Signature (MacOS Only)
  // Binaries on Mac are signed; modifying them breaks the
  // signature. We must strip it first.
  if (process.platform === 'darwin') {
    log(`🍎 Removing binary signature...`);
    try {
      run(`codesign --remove-signature "${EXE_NAME}"`);
    } catch {
      console.warn('⚠ Could not remove signature (this is normal if binary is unsigned).');
    }
  }
  // 6. Inject the Bundle into the Binary
  log(`💉 Injecting payload...`);
  const postjectCmd = `npx postject "${EXE_NAME}" NODE_SEA_BLOB ${SEA_PREP_BLOB} --sentinel-fuse ${SENTINEL_FUSE}`;
  // MacOS requires a specific segment name flag
  if (process.platform === 'darwin') {
    run(`${postjectCmd} --macho-segment-name NODE_SEA`);
  } else {
    run(postjectCmd);
  }
  log(`✅ Success! Executable created: ${EXE_NAME}`);
}

void build();
