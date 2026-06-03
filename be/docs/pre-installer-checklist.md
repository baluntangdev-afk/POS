# Pre-Installer Verification Checklist

Verify migrations and seeders are up to date before building the installer (`POSBackend.exe`).

## Why This Matters

The exe uses two index files at runtime instead of scanning the filesystem. If these are out of sync, the installer will run with missing or stale migrations/seeders.

| Index file | Used for | Sync script |
|---|---|---|
| `src/database/migrations-index.ts` | `POSBackend.exe --migrate` | `npm run migration:sync-index` |
| `src/database/seeders-index.ts` | `POSBackend.exe --seed` | `npm run seed:sync-index` |

---

## Checklist

### 1. Re-sync both indexes

```bash
npm run migration:sync-index
npm run seed:sync-index
```

Regenerates both index files by scanning actual `.ts` files on disk. If the reported count is unexpected, a migration or seeder is missing or was not exported with the correct interface.

### 2. Verify no pending migrations

```bash
npm run migration:show
```

Every migration must show `[X]` (executed). Any `[ ]` (pending) means `migration:up` must be run first.

### 3. Confirm the build compiles cleanly

```bash
npm run build
```

A missing or misspelled class in either index file will cause a compile error here — catch it before packaging.

### 4. Quick count check (optional spot-check)

Confirm the index entry count matches the file count.

**Migrations:**
```powershell
(Get-ChildItem src\database\migrations -Filter "*.ts" | Where-Object { $_.Name -match '^\d+' }).Count
(Select-String -Path src\database\migrations-index.ts -Pattern "import \{").Count
```

**Seeders:**
```powershell
(Get-ChildItem src\database\seeders -Filter "*.seeder.ts").Count
(Select-String -Path src\database\seeders-index.ts -Pattern "import \{").Count
```

Both pairs must match.

---

## Notes

- `src/database/migrations/index.ts` is a separate partial file — it is **not** the one used by the exe. The correct file is `src/database/migrations-index.ts` at the root of `database/`.
- Always run `migration:sync-index` and `seed:sync-index` after adding, generating, or deleting any migration or seeder file.
