# Product Management (Add / Edit / Delete) — Design Spec

**Date:** 2026-07-03
**Branch:** feature/optimize
**Scope:** Backend variant-pricing gap fixes + admin guarding, kiosk product CRUD dialog wired into `CatalogGridScreen`, retirement of the orphaned admin-CRUD stack

---

## Problem

`CatalogGridScreen` has "Add Product" and "Manage" affordances that are TODO stubs — there is no way to create, edit, or delete a product (or its variants) from the kiosk today. A separate, unreachable "admin CRUD" stack (`Product`/`ProductVariant`/`ProductsApi`/`product_dialogs.dart`/etc.) already implements product add/edit/delete with image upload, but it's dead code built against a different, incompatible model shape (`CatalogProduct` vs. `Product`) and isn't wired into the router in any live path.

Separately, the backend has a real data-integrity gap: `CreateProductVariantDto` has no `price` field, and `CreateProductVariantService` never persists `isDefault` — so even the existing `POST /api/v1/product-variants` endpoint can't actually set a variant's price today.

---

## Context

- Two parallel kiosk product stacks exist. **Only the "catalog" stack is live**: `CatalogProduct`/`CatalogRepository`/`CatalogProductsNotifier`, feeding `CatalogGridScreen` via `GET /api/v1/catalog/products` (raw SQL in `CatalogService`). The other (`Product`/`ProductVariant`/`ProductsApi`, `products_screen.dart`, `product_dialogs.dart`, `product_groups_screen.dart`, `product_variants_screen.dart`, `product_detail_screen.dart`) is unreachable from `router.dart` and will be deleted as part of this work.
- "Categories" in the kiosk = `product_groups` table (see `2026-06-22-category-management-design.md`). Category CRUD already exists and is the pattern this feature follows.
- `ProductVariant` (`product_variants` table) already exists with `name`, `price`, `isDefault`, but:
  - `CreateProductVariantDto` only has `productId`, `name`, `isDefault` — **no `price`**.
  - `CreateProductVariantService` only ever sets `name` on create — **`isDefault` and `price` are silently dropped** even though the DTO/entity have them.
  - `UpdateProductVariantService` sets `name` + `isDefault` but not `price`.
- `GET /api/v1/products/:id` → `ProductDetailsDto` already returns a full `variants[]` array (id, name, price, isDefault) and a computed `displayPrice`/`defaultVariantId` — this read path is correct today, only the write path is broken.
- `CatalogService.getProducts()` (backs the grid) reads `p.price::text` directly off the `products` row — it does **not** join variants. This raw SQL is flagged in `CLAUDE.md` as sensitive; this feature avoids touching it.
- No shared "variant type" catalog (e.g., a `SizeOption` table) exists anywhere. Variant names are free text per product.
- `ProductsController` / `ProductVariantsController` currently have **no role guard** — any authenticated user can create/edit/delete products and variants. `CatalogAdminController` established the `AdminOrSupervisorGuard` pattern this feature will reuse.
- Image upload precedent already exists end-to-end in the orphaned stack: `image_picker` package, `ImagePickerFormField` widget (`kiosk/lib/widgets/image_picker_form_field.dart`, **kept, not orphaned**), multipart `FormData` upload, `FileInterceptor('image')` + `multer` memory storage on the backend, `Buffer` → base64 stored directly in the `products.image_url` TEXT column.

---

## Decisions

1. **Variant naming**: an `Autocomplete<String>` suggesting names already used anywhere in the system (via a new `GET /api/v1/product-variants/names` endpoint), but free text is always allowed — this is guidance, not a closed list.
2. **Data stack**: extend the live `CatalogProduct`/`CatalogRepository`/`CatalogProductsNotifier` stack. Delete the orphaned admin-CRUD stack entirely.
3. **Pricing model**: every product must have at least one variant (no separate base-price form field). Each variant's price is manually entered by the admin. The product's card-level `price` (read by `CatalogService.getProducts()`) is kept in sync server-side as `MIN(price)` across the product's active variants, recomputed whenever a variant is created, updated, or deleted. This avoids touching the raw SQL in `CatalogService`.
4. **Default variant**: `isDefault` remains a separate concept from pricing — it marks which variant is pre-selected during ordering (`defaultVariantId` in `ProductDetailsDto`, used by the ordering flow). The dialog lets the admin mark one variant as default via a small per-row toggle; the first variant added is auto-marked default if the admin never touches the toggle.
5. **Role gating**: Add/Edit/Delete Product actions are admin/supervisor-only, matching category management. Backend mutating routes get `AdminOrSupervisorGuard`; kiosk UI hides the affordances via `loginStateProvider`'s `isAdminOrSupervisor`.
6. **Edit image preview**: shown as a static read-only thumbnail (`Image.network`, same widget the product card already uses) above the picker. The picker itself starts empty; picking a new image replaces the product's image on save, leaving it untouched sends no `image` field to `PATCH`.
7. **No product description field** in this dialog — not part of the requested form (name, category, variants, image only). The backend `description` column is simply left unset/unchanged by this flow.

---

## Backend Changes

### 1. `CreateProductVariantDto` / variant services

Files:
- `be/src/products/dto/create-product.variant.dto.ts` — add `price: number` (`@IsNotEmpty() @IsNumber() @Type(() => Number)`)
- `be/src/products/services/create-product-variant.service.ts` — persist `price` and `isDefault` (currently only `name` is set)
- `be/src/products/services/update-product-variant.service.ts` — persist `price` in addition to existing `name`/`isDefault`

### 2. Product price sync

New private helper in `ProductVariantsService` (or a small injected service), invoked at the end of `create`, `update`, and `remove`:

```
recomputeProductPrice(productId):
  price = MIN(price) over product_variants
          WHERE product_id = :productId AND deleted_at IS NULL AND status = 'Active'
  UPDATE products SET price = COALESCE(price, 0) WHERE id = :productId
```

Implemented as a repository query + `productsRepository.update(...)`, not raw SQL, consistent with the rest of `products.service.ts`.

### 3. New endpoint — existing variant names

- `be/src/products/services/find-distinct-variant-names.service.ts` (new) — `SELECT DISTINCT name FROM product_variants WHERE deleted_at IS NULL ORDER BY name ASC`
- `ProductVariantsController` — add `GET /product-variants/names` → `string[]`. Placed **above** `GET :id` in the controller so `/names` isn't swallowed by the `:id` route.

### 4. Role guarding

- `be/src/products/products.controller.ts` — add `@UseGuards(AdminOrSupervisorGuard)` to `create`, `update`, `remove`. `findAll`/`findOne` stay JWT-only (read access for the live catalog/ordering flows).
- `be/src/products/product-variants.controller.ts` — same: guard `create`, `update`, `remove`; leave `findByProductId`/`findOne`/`names` JWT-only.

### 5. What's NOT changed

- `CatalogService.getProducts()` raw SQL — untouched, keeps reading `products.price` directly.
- `ProductDetailsDto` / `FindProductDetailsService` — already correct, untouched.
- `CreateProductDto`/`UpdateProductDto` — unchanged (`groupId`, `name`, `description`); price is not a product-level input.

---

## Kiosk Changes

### 1. Models

File: `kiosk/lib/features/catalog/data/models/product.dart`
- Add `CatalogProductVariant` class: `id` (`String`, empty for unsaved), `name`, `price` (`double`), `isDefault` (`bool`). `fromJson`, `draft()`, `copyWith()`.
- `CatalogProduct` gains `variants: List<CatalogProductVariant>` (parsed when present; the grid's list endpoint doesn't return it, so default to `[]` there), plus `draft()` and `copyWith()` (currently has neither).

### 2. `CatalogRepository` — new methods

| Method | Endpoint | Notes |
|---|---|---|
| `createProduct(name, categoryId, imageBytes)` | `POST /api/v1/products` (multipart) | returns created `CatalogProduct` (id, name only — variants added separately) |
| `updateProduct(id, name, categoryId, imageBytes)` | `PATCH /api/v1/products/:id` (multipart) | `imageBytes == null` → no `image` field sent, existing image preserved |
| `deleteProduct(id)` | `DELETE /api/v1/products/:id` | |
| `fetchProductDetails(id)` | `GET /api/v1/products/:id` | used to hydrate the Edit dialog with full variant list |
| `createVariant(productId, name, price, isDefault)` | `POST /api/v1/product-variants` | |
| `updateVariant(id, name, price, isDefault)` | `PATCH /api/v1/product-variants/:id` | |
| `deleteVariant(id)` | `DELETE /api/v1/product-variants/:id` | |
| `fetchVariantNames()` | `GET /api/v1/product-variants/names` | autocomplete source |

Multipart pattern mirrors the orphaned `ProductsApi.create`/`update` (raw `FormData.fromMap` + `MultipartFile.fromBytes`, using `kiosk/lib/utils/file_sniffer.dart` for extension/mime), adapted to `CatalogRepository`'s plain-map style (no `dart_mappable` schema, matching how `createCategory`/`updateCategory` are written).

### 3. State

File: `kiosk/lib/features/catalog/state/catalog_products_notifier.dart`
- Add `static final saveAction = Mutation<CatalogProduct>()`, `static final deleteAction = Mutation<bool>()`.
- Add `Future<CatalogProduct> save(CatalogProduct draft, List<CatalogProductVariant> variants)`:
  1. Create or update the product (by `draft.id.isEmpty`) → get/confirm product id.
  2. On edit, re-fetch the product's current variants server-side (`fetchProductDetails(id).variants`) as the diff baseline — not the snapshot the dialog originally loaded with, so a stale client-side list can't cause an incorrect delete. Diff against the incoming `variants` list purely by `id`: rows with empty `id` → create; rows with non-empty `id` → update; any baseline variant `id` absent from the incoming list → delete. On create, every row has an empty `id`, so all are created and no baseline fetch/diff is needed.
  3. `getResults(...)` (existing method) to refresh the grid.
- Add `Future<bool> delete(String id)` — `deleteProduct(id)` then refresh.

New provider: `catalogVariantNamesProvider` (`FutureProvider<List<String>>`) wrapping `fetchVariantNames()`, in the same state file or a small new one.

### 4. Dialogs

New file: `kiosk/lib/features/catalog/view/product_dialogs.dart` (replaces the deleted orphaned one). Chrome matches `category_dialogs.dart` (`Dialog`, responsive width via `context.responsive`, `Form` + `SingleChildScrollView`, `Mutation`-driven Save/Delete, `showNetworkErrorDialog` on error).

**`SaveProductDialog({CatalogProduct? product})`**

Fields, top to bottom:
1. Title — "Add Product" / "Edit Product"
2. **Name** — `TextBoxFormField`, `Validate(rules: [isRequired()])`
3. **Category** — `DropdownButtonFormField<String>` sourced from `ref.watch(catalogCategoriesProvider)` (already loaded by the parent screen), required
4. **Variants** section:
   - Header + helper text: *"e.g. Regular, Venti"*
   - Repeating rows (`useState<List<_VariantDraft>>`, a local hook-state helper class, not the same as `CatalogProductVariant` — holds the two `TextEditingController`s + default flag + optional existing id): name (`Autocomplete<String>` from `catalogVariantNamesProvider`, free text allowed, `isRequired()`), price (`TextBoxFormField`, numeric keyboard, `isRequired()` + `minValue(0.01)`), a default-toggle (radio/star icon — selecting one clears the others), a remove (✕) icon button.
   - "Add Variant" button appends a blank row; first row added is auto-marked default.
   - Form-level validation (checked in the submit handler, not a per-field validator): at least 1 variant; no duplicate names (case-insensitive) among the rows — surfaced as a `showNetworkErrorDialog`-style inline message or a `SnackBar`, matching existing form-level-error conventions in the codebase.
5. **Image**:
   - If editing and `product.imageUrl` is non-empty: a read-only thumbnail (`Image.network(product.imageUrl)`, same error/placeholder handling as `_ProductImage` in `catalog_grid_screen.dart`) with a small "Current image" label.
   - `ImagePickerFormField` below it (unchanged widget), no validator, starts empty. Label reads "Replace Image" when editing with an existing image, "Image (optional)" otherwise.
6. Cancel / Save buttons — Save disabled while `saveStatus is MutationPending`, label "Saving..." / "Update" / "Save".

On submit: build the product draft + variant list, call `saveAction.run(ref, (txn) => txn.get(catalogProductsProvider.notifier).save(draft, variants))`. On `MutationSuccess`, pop the dialog.

When opening for edit, the dialog first needs the product's current variants — `showSaveProductDialog` fetches `fetchProductDetails(product.id)` before showing the form (or the dialog shows a brief loading state internally while it resolves), since `CatalogProduct` from the grid list has `variants: []`.

**`DeleteProductDialog({required CatalogProduct product})`** — identical structure/copy to `DeleteCategoryDialog`, "Delete Product" / product name in the confirmation text.

Public functions: `Future<CatalogProduct?> showSaveProductDialog(BuildContext, {CatalogProduct? product})`, `Future<bool?> showDeleteProductDialog(BuildContext, CatalogProduct product)`.

### 5. `catalog_grid_screen.dart` wiring

- `_FilterBar`: both the phone icon-button and the desktop "Add Product" `Button` currently render unconditionally with a TODO `onPressed`. Wire `onPressed: () => showSaveProductDialog(context)` and gate rendering on `isAdminOrSupervisor` (read via `ref.watch(loginStateProvider).value?.isAdminOrSupervisor ?? false` — `_FilterBar` becomes a `ConsumerWidget`/needs `WidgetRef`, or the flag is passed down from `CatalogGridScreen` which already has `ref`).
- `_ProductCard`'s "Manage" button (currently commented-out navigation) → replaced with an edit action (`showSaveProductDialog(context, product: product)`) plus a small trailing delete affordance (`PopupMenuButton`, mirroring `categories_tab.dart`'s `_ActionMenu`, with Edit/Delete items). Only rendered for admin/supervisor; non-admins see the card with no management UI, same as categories.
- `_ProductCard`/`_Grid`/`_ProductsGrid` need `isAdminOrSupervisor` threaded down from `CatalogGridScreen` (same shape as `categories_tab.dart` threads it to `_CategoryCard`).

### 6. Cleanup — delete orphaned stack

Confirmed unreferenced from `lib/navigation/router.dart` / `catalog_route.dart` except for mock-data screens; delete:
- `kiosk/lib/features/catalog/entities/product.dart`, `product_variant.dart`, `product_group.dart` (+ their `.mapper.dart`)
- `kiosk/lib/features/catalog/state/products_notifier.dart`
- `kiosk/lib/features/catalog/use_cases/save_product.dart`, `delete_product.dart`, `get_products.dart` (and any product-group/variant equivalents)
- `kiosk/lib/features/catalog/view/products_screen.dart`, `product_dialogs.dart` (old), `product_groups_screen.dart`, `product_group_dialogs.dart`, `product_variants_screen.dart`, `product_detail_screen.dart`
- `kiosk/lib/data/backend_api/sources/products_api.dart`, `product_variants_api.dart`, and their now-unused schemas (`create_product_dto.dart`, `update_product_dto.dart`, `product_dto.dart`, `product_details_dto.dart`, `product_query_dto.dart` — verify no other live code imports these before deleting)
- Corresponding dead routes in `lib/navigation/catalog_route.dart` / `router.g.dart` (regenerate via `build_runner` after)
- `image_picker_form_field.dart` is **kept** — reused by the new dialog.

Exact file list will be re-verified with a grep pass at implementation time before deleting anything (per repo-wide "investigate before deleting" convention).

---

## Data Flow

```
CatalogGridScreen (isAdminOrSupervisor from loginStateProvider)
  → "Add Product" → showSaveProductDialog(context)
      → SaveProductDialog (variants: [])
  → Card → Edit → showSaveProductDialog(context, product: p)
      → fetch full variants via fetchProductDetails(p.id)
      → SaveProductDialog (variants: [...])
          → submit → saveAction
              → CatalogProductsNotifier.save(draft, variants)
                  → CatalogRepository.createProduct/updateProduct  (multipart, image optional)
                      → POST/PATCH /api/v1/products[/:id]  (AdminOrSupervisorGuard)
                  → diff variants → createVariant/updateVariant/deleteVariant per row
                      → POST/PATCH/DELETE /api/v1/product-variants[/:id]  (AdminOrSupervisorGuard)
                          → recomputeProductPrice(productId)  [MIN(variant price) → products.price]
                  → getResults(...) refresh
      → on success: Navigator.pop
  → Card → Delete → showDeleteProductDialog(context, p)
      → deleteAction → CatalogProductsNotifier.delete(p.id)
          → CatalogRepository.deleteProduct(p.id) → DELETE /api/v1/products/:id
          → getResults(...) refresh
      → on success: Navigator.pop
```

---

## Validation Summary

| Field | Rule |
|---|---|
| Name | required |
| Category | required (non-empty selection) |
| Variant name | required per row; suggested via autocomplete, free text allowed; no duplicates within the product (case-insensitive) |
| Variant price | required per row; `minValue(0.01)` |
| Variants (overall) | at least 1 row required |
| Image | optional, no validator |

---

## Error Handling

- All mutations surface errors via `showNetworkErrorDialog(context, error:)`, matching category management.
- Form-level errors (no variants, duplicate variant names) block submission before any network call — surfaced inline, not via the network error dialog.
- If variant sync partially fails mid-diff (e.g., 2 of 3 variant calls succeed before an error), the dialog surfaces the error and the product list is refreshed on next load — no client-side rollback of already-applied variant changes. This mirrors the general lack of cross-request transactions elsewhere in this codebase (e.g., category save is a single request, but product+variants here is inherently multi-request); acceptable for an admin tool with a visible retry path (edit again, fix the mismatch).

---

## What Is NOT Changed

- `CatalogService.getProducts()` raw SQL / response shape consumed by `catalog_grid_screen.dart`'s read path.
- `ProductDetailsDto` / `FindProductDetailsService` (already correct).
- `CreateProductDto`/`UpdateProductDto` shape (`groupId`, `name`, `description`) — no product-level price field added.
- Modifier groups — untouched, out of scope.
- Product description — not exposed in this dialog; left as-is on the entity.
- Ordering flow's use of `defaultVariantId` — untouched, this feature only adds a way to set `isDefault` from the admin UI.
