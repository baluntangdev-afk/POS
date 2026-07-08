# Product/Category/Variant Enable-Disable (Replace Delete) — Design Spec

**Date:** 2026-07-06
**Branch:** feature/create-product
**Scope:** Replace the permanent-feeling "Delete" action for categories, products, and product variants with a reversible enable/disable toggle. No hard deletes, no new "delete anything" affordance anywhere in the admin UI.

---

## Problem

Categories and products can currently be "deleted" from the kiosk admin UI. Under the hood this is a TypeORM soft-delete (`deletedAt` is set, the row survives in Postgres) — but from the app's perspective it's a one-way trip: the item vanishes from every list and there is no UI to bring it back. The confirmation dialogs even say "This action cannot be undone."

The business reason to delete something is almost always "we don't sell this right now," not "this should never exist again" — a seasonal item, a mis-priced product pulled temporarily, a category being reorganized. The current flow makes all of these look destructive and permanent when they aren't.

Products are the newer of the two flows (built as part of the in-progress product add/edit/delete feature, commit `9dd247f`) and are about to ship with the exact same one-way-trip problem categories already have. This is the last point where changing course is cheap.

## Goals

- Replace "Delete" with "Disable" (and "Enable" to reverse it) for: categories, products, and product variants.
- Disabled items disappear from customer-facing ordering/catalog surfaces, exactly as they do today when soft-deleted.
- Disabled items remain visible to admins/supervisors (greyed out, labeled) so they can be re-enabled.
- No data is ever hard-deleted or soft-deleted by this UI. `DELETE` routes/services tied to these three entities are retired.

## Non-goals

- No new confirmation-dialog-free UX pattern is being introduced elsewhere in the app — this only touches category/product/variant management.
- No change to `product_modifier_groups`, modifier groups, or modifier options — out of scope.
- No change to the ordering/sales feature's data stack (`features/sales/...`) beyond making sure it doesn't surface disabled products/variants — its architecture is untouched.
- No true "permanently delete" admin action is added anywhere (confirmed with the user — enable/disable fully replaces delete, no exceptions).

---

## Data model — no schema changes

Every flag needed already exists on the entities; this is a behavior change, not a migration:

| Entity | Table | Existing column | Values |
|---|---|---|---|
| `ProductGroup` (category) | `product_groups` | `status` | `Active` / `Cancelled` (`BaseStatus`) |
| `Product` | `products` | `is_available` | boolean, default `true` |
| `ProductVariant` | `product_variants` | `status` | `Active` / `Disabled` (`ProductVariantStatus`) |

Categories already toggle `status` via `isActive` in `createCategory`/`updateCategory` (`be/src/catalog/catalog.service.ts:96-139`) — that part is done and unchanged by this spec. Products and variants don't expose their flag through any API yet; that's the gap this spec closes.

**UI wording:** "Enable" / "Disable" everywhere (categories, products, variants), per user decision — not "Available/Unavailable" or "Hide/Unhide", even though the underlying product field is named `isAvailable`.

---

## Backend changes

### 1. Categories — retire the delete route, nothing else needed

- Remove `DELETE /catalog/admin/categories/:id`: delete `CatalogAdminController.deleteCategory` (`be/src/catalog/catalog-admin.controller.ts:78-97`) and `CatalogService.deleteCategory` (`be/src/catalog/catalog.service.ts:141-148`).
- No new endpoint needed — disabling a category is already just `updateCategory` with `isActive: false`, which the kiosk will call directly (see Kiosk section).
- Delete/update any tests covering the removed route/method.

### 2. Products — expose `isAvailable`, retire delete

- `CreateProductDto` (`be/src/products/dto/create-product.dto.ts`): add `isAvailable?: boolean`, optional, defaulting to `true` when creating. Since product create/update use `multipart/form-data` (image upload), a plain `@Type(() => Boolean)` is not sufficient — form fields arrive as the strings `"true"`/`"false"`, and `Boolean("false")` is `true`. Use an explicit transform, e.g. `@Transform(({ value }) => value === true || value === 'true')`.
- `UpdateProductDto` inherits automatically (`PartialType(CreateProductDto)`).
- `CreateProductService` / `UpdateProductService` (`be/src/products/services/{create-product,update-product}.service.ts`): pass `isAvailable` through to the repository call.
- Remove `DELETE /products/:id`: delete `ProductsController.remove` (`be/src/products/products.controller.ts:129-136`) and `DeleteProductService` (`be/src/products/services/delete-product.service.ts`). Drop it from `ProductsModule` providers and remove its spec file.

### 3. Product variants — add an `isActive` toggle, retire delete

- `UpdateProductVariantDto` (`be/src/products/dto/update-product-variant.dto.ts`, currently just `PartialType(CreateProductVariantDto)`): add `isActive?: boolean` directly on this DTO (not inherited from create — a variant's enable state is only ever changed via update, never set at creation time, so it doesn't belong on `CreateProductVariantDto`).
- `UpdateProductVariantService`: when `isActive` is present, map it to `status: isActive ? ProductVariantStatus.ACTIVE : ProductVariantStatus.DISABLED`, mirroring `CatalogService.updateCategory`'s existing `isActive` → `status` mapping (`catalog.service.ts:123-125`).
- Remove `DELETE /product-variants/:id`: delete `ProductVariantsController.remove` and `DeleteProductVariantService`. Drop it from `ProductsModule` providers and remove its spec file.

### 4. Admin needs to see disabled products (new gap to close)

Today, `CatalogGridScreen` (the kiosk's product-management screen) reads products via `CatalogService.getProducts()` (`be/src/catalog/catalog.service.ts:150-231`), which unconditionally filters `p.status = 'Active' AND p.is_available = true AND p.deleted_at IS NULL`. This is correct for customer ordering but means an admin who disables a product will lose the ability to see or re-enable it — there is currently no admin-inclusive product listing (unlike categories, which already have `getAllCategoriesForAdmin`).

Add an admin-inclusive path, mirroring the categories pattern:
- `CatalogService.getProducts()` gains an optional parameter (e.g. `includeDisabled: boolean`) that, when true, drops the `p.status = 'Active' AND p.is_available = true` conditions (keeping `p.deleted_at IS NULL`).
- `CatalogAdminController` gains `GET /catalog/admin/products` (JWT-only, no admin guard — same as `GET /catalog/admin/categories`, which any authenticated user can read; only mutations are guarded) that calls it with `includeDisabled: true`.

### 5. Keep disabled items out of customer-facing reads

`CatalogService.getProducts()` already excludes disabled/unavailable products from the customer/ordering path — no change needed the. Two things need explicit verification/fixing during implementation:

- `FindProductDetailsService` (`be/src/products/services/find-product-details.service.ts`) backs `GET /api/v1/products/:id`, which is used **both** by the admin edit dialog (needs to see *all* variants, including disabled ones, so they can be re-enabled) **and** by the customer ordering flow (`features/sales/...` in kiosk, needs only active variants). The backend response should keep returning all variants (don't filter server-side — that would break the admin dialog); instead the variant's `status`/`isActive` must be included in `ProductDetailsDto` so each consumer can filter appropriately. The ordering flow (kiosk) must filter to active variants client-side; the catalog admin dialog does not filter.
- Audit the ordering feature's own read paths (`features/sales/repositories/product_repository.dart`, `product_group_repository.dart`, and whatever backend queries they hit) to confirm they already exclude `is_available = false` / disabled-status products the same way `CatalogService.getProducts()` does. This wasn't in scope for the original product-management work and needs a fresh check now that disabling becomes a real, reachable state instead of a soft-delete-only edge case.

---

## Kiosk changes

### 1. Categories tab (`kiosk/lib/features/catalog/view/categories_tab.dart`)

- `_ActionMenu` (lines 326-376): replace the `delete` action/menu item with a `disable`/`enable` item whose label and icon flip based on `category.isActive` ("Disable" + `Icons.block_rounded` when active, "Enable" + `Icons.check_circle_outline_rounded` when inactive). No confirmation dialog — the action is instantly reversible.
- Selecting it calls a new lightweight notifier method (see below) directly; it does not open `SaveCategoryDialog`.
- `_CategoryAction` enum: `edit`, `toggleActive` (renamed from `delete`).
- The existing "Active"/"Inactive" badge (lines 256-267) is unchanged — it already reflects `isActive`.

### 2. `CatalogCategoriesNotifier` (`kiosk/lib/features/catalog/state/catalog_categories_notifier.dart`)

- Replace `delete(String id)` (lines 52-56) with `toggleActive(CatalogCategory category)`: calls `repo.updateCategory(category.id, category.name, category.description, !category.isActive)`, then `refresh()`.
- `deleteAction` mutation can be removed if nothing else references it (confirm via search before deleting).

### 3. `CatalogRepository` (`kiosk/lib/features/catalog/data/catalog_repository.dart`)

- Remove `deleteCategory` (lines 75-77), `deleteProduct` (lines 140-142), `deleteVariant` (lines 183-185).
- Add `fetchAllProductsAdmin({String? categoryId, String? search})` hitting the new `GET /api/v1/catalog/admin/products`, mirroring `fetchAllCategoriesAdmin` (lines 32-38).
- `createVariant`/`updateVariant`: `updateVariant` gains an `isActive` parameter, sent as `{'isActive': isActive}` alongside existing fields (`createVariant` does not need it — new variants are always created active).

### 4. `CatalogProduct` / `CatalogProductVariant` models (`kiosk/lib/features/catalog/data/models/product.dart`)

- `CatalogProductVariant` gains `isActive` (bool, parsed from the backend's `status`/`isActive` field, defaulting to `true` if absent for backward compatibility with the grid's list endpoint, which doesn't return variants at all). Update `fromJson`, `copyWith`.
- `CatalogProduct.isAvailable` already exists (line 62) — no model change needed there.

### 5. `CatalogProductsNotifier` (`kiosk/lib/features/catalog/state/catalog_products_notifier.dart`)

- `build()` (lines 35-39) and `getResults()` (lines 41-54) switch from `fetchProducts` to `fetchAllProductsAdmin`, since this notifier only backs the admin `CatalogGridScreen` (confirmed: the customer ordering flow uses the separate `features/sales` stack, untouched by this spec).
- Replace `delete(String id)` (lines 114-119) with `toggleAvailability(CatalogProduct product)`: calls a new repo method `updateProductAvailability(id, isAvailable)` (a plain JSON `PATCH /products/:id` with just `{'isAvailable': ...}` — no need to resend name/category/image), then refreshes.
- In `save()` (lines 56-112), the variant diff loop currently does `create` for new rows, `update` for existing rows, and `deleteVariant` for rows removed from the incoming list (lines 104-106). Change the removed-row handling: instead of `deleteVariant(removedId)`, call `updateVariant(id: removedId, ..., isActive: false)` — i.e., a row dropped from the UI list gets disabled, not deleted. (This requires fetching the removed variant's current name/price to satisfy `updateVariant`'s existing required params, or relaxing `updateVariant` to accept a partial payload — simplest fix is making `updateVariant`'s repository method accept only the fields being changed and have the backend DTO already be fully optional via `PartialType`, sending just `{'isActive': false}`.)

### 6. `SaveProductDialog` variant rows (`kiosk/lib/features/catalog/view/product_dialogs.dart`)

- `_VariantRow` (lines 336-373): add `bool isActive`, initialized from `variant.isActive` (default `true` for new/blank rows).
- `_VariantRowField` (lines 467-555): replace the ✕ "Remove" `IconButton` (lines 544-551, and the `onRemove` callback threaded from `_VariantsSection.removeRow`) with a toggle affordance for existing rows — e.g. a switch or a filled/outline icon button (`Icons.visibility_rounded` / `Icons.visibility_off_rounded`) that flips `row.isActive`. Disabled rows stay in the list, visually greyed out (reduced opacity / muted text), rather than disappearing.
- For **new, unsaved rows** (empty `id`, added via "Add Variant" this session), keep a real remove button — there's nothing to disable yet since it was never saved. Only rows with a non-empty `id` (i.e., existing persisted variants) get the disable toggle instead of removal.
- `_validateVariantRows` (lines 375-392): "at least one variant" is only enforced against **active** rows — a product can have every variant disabled in the data model, but the form shouldn't require a phantom active one just to pass validation. "No duplicate names" is checked across **all** rows regardless of active state, so re-adding a variant with the same name as an already-disabled one is rejected — the admin should re-enable the existing row instead of creating a duplicate.

### 7. `DeleteProductDialog` / `showDeleteProductDialog` / `DeleteCategoryDialog` / `showDeleteCategoryDialog`

Both dialogs (`product_dialogs.dart:557-687`, `category_dialogs.dart:29-34` and `188-313`) are deleted outright — no dialog is needed for a reversible action. Confirm via import grep that nothing else references them before deleting.

### 8. `catalog_grid_screen.dart` product card (around lines 580-613)

- The trash `IconButton` (`onPressed: () => showDeleteProductDialog(...)`) becomes a toggle icon button calling `ref.read(catalogProductsProvider.notifier).toggleAvailability(product)` directly, with icon/tooltip flipping based on `product.isAvailable`.
- Add a "Disabled" badge (matching the category tab's Active/Inactive treatment) and reduced-opacity styling on the card when `!product.isAvailable`, since disabled products will now actually appear in this admin grid instead of disappearing.

---

## Testing

- Backend: unit tests for the updated `CreateProductService`/`UpdateProductService` (isAvailable passthrough, including the multipart string-to-bool transform), `UpdateProductVariantService` (isActive → status mapping), and `CatalogService.getProducts`'s new `includeDisabled` branch. Delete the spec files for the removed `DeleteProductService`/`DeleteProductVariantService`/`CatalogService.deleteCategory` and remove their route tests from the relevant controller specs.
- Kiosk: update/replace any widget or unit tests referencing `showDeleteProductDialog`/`showDeleteCategoryDialog`/`deleteProduct`/`deleteCategory`/`deleteVariant`.
- Manual verification: disable a product from the admin grid → confirm it still shows (greyed, badge) in the admin grid, and disappears from the actual customer ordering flow. Re-enable → confirm it reappears for ordering. Same check for a category, and for disabling a single variant on a multi-variant product.

---

## Open questions to resolve during implementation (not blocking spec approval)

- Exact query/file list for the "ordering feature must not show disabled products/variants" audit (Backend section 5) — needs a grep pass over `features/sales/` during plan-writing, not guessed here.
