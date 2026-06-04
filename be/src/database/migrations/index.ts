import type { MigrationInterface } from 'typeorm';
import { TestInit1770175003018 } from './1770175003018-test-init';
import { UsersRole1779583700000 } from './1779583700000-users-role';
import { SalesOrdersVoidFields1779583800000 } from './1779583800000-sales-orders-void-fields';
import { SalesOrdersDoneExport1779584000000 } from './1779584000000-sales-orders-done-export';
import { SoItemsSaleTypeNote1779584100000 } from './1779584100000-so-items-sale-type-note';
import { PaymentsMethodName1779584200000 } from './1779584200000-payments-method-name';

/**
 * Migration classes for POSBackend.exe --migrate (same as npm run migration:up).
 * Auto-synced by scripts/sync-migrations-index.js when creating or generating migrations.
 */
export const migrations: Array<new () => MigrationInterface> = [
  TestInit1770175003018,
  UsersRole1779583700000,
  SalesOrdersVoidFields1779583800000,
  SalesOrdersDoneExport1779584000000,
  SoItemsSaleTypeNote1779584100000,
  PaymentsMethodName1779584200000,
];
