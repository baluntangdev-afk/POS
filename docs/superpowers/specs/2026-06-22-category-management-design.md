# Category Management (Admin/Supervisor) — Design Spec

**Date:** 2026-06-22  
**Branch:** feature/optimize  
**Scope:** Backend CRUD endpoints for categories + kiosk UI (dialogs, role-gated actions)

---

## Problem

The `CategoriesTab` in the Catalog Management screen is read-only. Admins and supervisors have no way to create, edit, or delete categories from the kiosk. The `Add Category` button and card tap handlers are TODO stubs.

---

## Context

- "Categories" in the kiosk = `product_groups` table on the backend.
- `GET /api/v1/catalog/categories` is `@Public()` and returns only active product groups.
- `ProductGroupsController` has full CRUD but uses multipart/form-data and a different response shape.
- The JWT payload carries `systemAdmin` but not `role`. Role values: `user`, `admin`, `supervisor`.

---

## Architecture Decision

**New `CatalogAdminController`** — separate from the existing public `CatalogController`. JSON endpoints (no image upload). All four routes gated behind JWT + `AdminOrSupervisorGuard`.

The public `GET /catalog/categories` endpoint is untouched.

---

## Backend Changes

### 1. JWT payload — add `role`

Files:
- `be/src/auth/dto/jwt-payload.dto.ts` — add `role: string`
- `be/src/auth/dto/me.dto.ts` — add `role: string`
- `be/src/auth/strategies/jwt.strategy.ts` — map `payload.role` → returned `MeDto`
- `be/src/auth/auth.service.ts` — include `user.role` in both access and refresh `buildTokens()` payloads

Existing tokens remain valid — `role` will be absent on old tokens. `MeDto.role` must be declared optional (`role?: string`) and default to `'user'` in `JwtStrategy.validate()` when missing, so existing sessions are never broken.

### 2. `AdminOrSupervisorGuard`

New file: `be/src/auth/guards/admin-or-supervisor.guard.ts`

```ts
// Allows only users whose role is 'admin' or 'supervisor'.
// Apply after JwtAuthGuard so req.user is populated.
```

Pattern mirrors `SystemAdminGuard`. Throws `ForbiddenException` if role is not admin/supervisor.

### 3. DTOs

New directory: `be/src/catalog/dto/`

- `create-category.dto.ts` — `name: string` (required), `description?: string`, `isActive?: boolean` (default true)
- `update-category.dto.ts` — `PartialType(CreateCategoryDto)`

### 4. `CatalogService` additions

Inject `@InjectRepository(ProductGroup) private readonly pgRepo: Repository<ProductGroup>`.

New methods:

| Method | SQL / ORM | Notes |
|---|---|---|
| `getAllCategoriesForAdmin()` | Same query as `getCategories()` but **without** `WHERE pg.status = 'Active'` | Returns all categories incl. inactive |
| `createCategory(dto, causer)` | `pgRepo.save({ name, description, status, createdBy })` | `status = isActive ? 'Active' : 'Inactive'` |
| `updateCategory(id, dto, causer)` | `pgRepo.update(id, {...})` then re-query | Partial update; only provided fields change |
| `deleteCategory(id, causer)` | set `deletedBy`, then `pgRepo.softDelete(id)` | Same soft-delete pattern as `ProductGroupsService.remove()` |

### 5. `CatalogAdminController`

New file: `be/src/catalog/catalog-admin.controller.ts`

Routes (all under the global `api/v1` prefix):

| Method | Path | Guard | Handler |
|---|---|---|---|
| GET | `/catalog/admin/categories` | JWT only | `getAllCategoriesForAdmin()` |
| POST | `/catalog/admin/categories` | JWT + AdminOrSupervisor | `createCategory(dto, user)` |
| PATCH | `/catalog/admin/categories/:id` | JWT + AdminOrSupervisor | `updateCategory(id, dto, user)` |
| DELETE | `/catalog/admin/categories/:id` | JWT + AdminOrSupervisor | `deleteCategory(id, user)` |

Any authenticated user can list all categories (including inactive) for management display. Only admin/supervisor can mutate.

Response envelope: `{ success: true, data: ... }` — matches existing catalog controller style.

### 6. `CatalogModule`

- Add `TypeOrmModule.forFeature([ProductGroup])`
- Add `CatalogAdminController` to `controllers` array
- Import `ProductGroupsModule` is NOT needed (direct repository injection)

---

## Frontend Changes (kiosk)

### 1. `Auth` entity

File: `kiosk/lib/features/auth/entities/auth.dart`

Add `role` field (`String`, default `'user'`). `@MappableClass` — run `build_runner` after.

### 2. `AuthRepository`

Map `UserDto.role` → `Auth.role` in `_authFromUserDto()`.

### 3. `CatalogRepository`

File: `kiosk/lib/features/catalog/data/catalog_repository.dart`

Add 4 new methods:

| Method | Endpoint | Body |
|---|---|---|
| `fetchAllCategoriesAdmin()` | `GET /api/v1/catalog/admin/categories` | — |
| `createCategory(name, description, isActive)` | `POST /api/v1/catalog/admin/categories` | JSON |
| `updateCategory(id, name, description, isActive)` | `PATCH /api/v1/catalog/admin/categories/:id` | JSON |
| `deleteCategory(id)` | `DELETE /api/v1/catalog/admin/categories/:id` | — |

`createCategory` / `updateCategory` return `CatalogCategory` (parsed from response `data`).  
`deleteCategory` returns `void`.

### 4. `CatalogCategory` model

File: `kiosk/lib/features/catalog/data/models/category.dart`

Add:
- `copyWith(...)` — for pre-populating the edit dialog
- `CatalogCategory.draft()` factory — blank category for the create flow

### 5. `CatalogCategoriesNotifier`

File: `kiosk/lib/features/catalog/state/catalog_categories_notifier.dart`

Changes:
- `build()` calls `fetchAllCategoriesAdmin()` instead of `fetchCategories()` — so the management tab shows all categories including inactive. The new endpoint is JWT-only (not role-gated), so any authenticated user can still load the tab without errors.
- Add `static final saveAction = Mutation<CatalogCategory>()`
- Add `static final deleteAction = Mutation<bool>()`
- Add `Future<CatalogCategory> save(CatalogCategory category)` — calls create or update based on whether `category.id` is non-empty
- Add `Future<bool> delete(String id)` — calls `deleteCategory(id)`, then calls `refresh()`

### 6. `category_dialogs.dart`

New file: `kiosk/lib/features/catalog/view/category_dialogs.dart`

Two dialogs:

**`SaveCategoryDialog`** (create + edit):
- Form fields: Name (required), Description (optional), Active toggle (`Switch`)
- Pre-populates from `CatalogCategory?` when editing
- Pattern: identical to `SaveProductGroupDialog` but without image picker
- On save: calls `CatalogCategoriesNotifier.saveAction.run(...)`
- On success: `Navigator.pop(result)` — caller refreshes list

**`DeleteCategoryDialog`**:
- Confirmation with category name
- Pattern: identical to `DeleteProductDialog`
- On confirm: calls `CatalogCategoriesNotifier.deleteAction.run(...)`
- On success: `Navigator.pop(true)`

Public functions:
- `Future<CatalogCategory?> showSaveCategoryDialog(BuildContext, {CatalogCategory?})`
- `Future<bool?> showDeleteCategoryDialog(BuildContext, CatalogCategory)`

### 7. `CategoriesTab` / `_CategoryCard` updates

File: `kiosk/lib/features/catalog/view/categories_tab.dart`

- `_CategoriesGrid`: wire `Add Category` button → `showSaveCategoryDialog(context)`. No manual invalidate needed — `notifier.save()` and `notifier.delete()` each call `refresh()` internally before returning.
- `_CategoryCard`: becomes `ConsumerWidget`. Read `loginStateProvider` to get current user role.
  - Show edit icon button (pencil) → `showSaveCategoryDialog(context, category: category)`
  - Show delete icon button (trash) → `showDeleteCategoryDialog(context, category)`
  - Both buttons render only when `user.role == 'admin' || user.role == 'supervisor'`
  - Buttons positioned in the top-right of the card (alongside the Active/Inactive badge)

---

## Data Flow

```
CategoriesTab
  → ref.watch(catalogCategoriesProvider)  [fetchAllCategoriesAdmin on build]
  → Add/Edit button → showSaveCategoryDialog
      → SaveCategoryDialog.save()
          → CatalogCategoriesNotifier.saveAction
              → notifier.save(category)
                  → CatalogRepository.createCategory / updateCategory
                      → POST/PATCH /api/v1/catalog/admin/categories[/:id]
                          → CatalogAdminController
                              → CatalogService.createCategory / updateCategory
      → on success: notifier.refresh() + Navigator.pop
  → Delete button → showDeleteCategoryDialog
      → DeleteCategoryDialog.delete()
          → CatalogCategoriesNotifier.deleteAction
              → notifier.delete(id)
                  → CatalogRepository.deleteCategory
                      → DELETE /api/v1/catalog/admin/categories/:id
                          → CatalogAdminController
                              → CatalogService.deleteCategory
      → on success: notifier.refresh() + Navigator.pop
```

---

## Error Handling

- All mutations use `showNetworkErrorDialog(context, error: error)` on `MutationError` — matches existing pattern.
- Backend returns `{ success: false, error: message }` with appropriate HTTP status on failure.
- Duplicate name: backend unique constraint on `product_groups.name` returns 409/500; shown in network error dialog.

---

## What Is NOT Changed

- `GET /api/v1/catalog/categories` (public, read-only) — untouched
- `ProductGroupsController` — untouched
- Kiosk ordering flow (uses its own providers, unaffected)
- No image upload in category management (out of scope)
- No sort order field (out of scope)
