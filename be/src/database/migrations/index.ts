import type { MigrationInterface } from 'typeorm';
import { TestInit1770175003018 } from './1770175003018-test-init';

/**
 * Migration classes for POSBackend.exe --migrate (same as npm run migration:up).
 * Auto-synced by scripts/sync-migrations-index.js when creating or generating migrations.
 */
export const migrations: Array<new () => MigrationInterface> = [TestInit1770175003018];
