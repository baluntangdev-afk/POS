# Mobile Inventory Management — Align with Kiosk

## Context

The kiosk (Flutter/Windows, online, talks to the NestJS backend) and mobile (Flutter, fully offline, local `drift`/SQLite) apps both have an "Inventory Management" feature, but it's really a **product/category/modifier catalog editor** in both — neither has stock/quantity tracking. The two implementations have diverged:

| Aspect | Kiosk (today) | Mobile (today) |
|---|---|---|
| Pricing | Product → multiple named **variants** (name, price, isDefault, isActive) | Product → single flat `price` field |
| Modifier groups | Global/shared entities, linked to products via `product_modifier_groups` junction table | Owned 1:1 by a single product (explicit "Phase 3 Design Decision #2") |
| Delete semantics | No hard deletes anywhere — categories/variants are soft-toggled via `isActive`; products have no delete action, only an availability toggle | Hard delete for products (cascades to modifier groups/options) and categories (blocked only if it still has products) |
| Screen layout | `InventoryScreen` with **Products** / **Categories** tabs (a 3rd Modifier Groups tab exists in code but is hidden/non-functional) | Single screen; categories managed via a bottom sheet; modifier groups managed per-product via a separate route |
| Role gating | Add/Edit/Delete/toggle-availability hidden from non-admin/supervisor users (`isAdminOrSupervisor`), UI-only | No role gating on inventory actions |
| Backend | Remote NestJS API over Dio | None — fully offline, local SQLite via drift |

Goal: bring mobile's inventory management to full parity with kiosk's model and UX, while keeping mobile fully offline (no network/sync layer — that's an explicitly separate, much larger effort if ever undertaken).

## Decisions

1. **Scope**: full parity — both UI/UX flow and underlying data model, not just a visual reskin.
2. **Stay offline**: no backend/API layer added to mobile. This is purely a local schema + UI restructuring.
3. **Add variants**: mobile products gain a `product_variants` table matching kiosk's shape (`id`, `productId`, `name`, `price`, `isDefault`, `isActive`). The existing single `price` field is retired after migration.
4. **Modifier groups become shared/reusable**: drop the `productId` FK from `modifier_groups`; add a `product_modifier_groups` junction table, matching kiosk's model exactly. A group created once can be attached to multiple products.
5. **Delete → soft-disable everywhere**: remove hard-delete actions for products, categories, modifier groups, and modifier options from the inventory UI. Replace with `isActive`/availability toggles, matching kiosk's "nothing is really deleted" philosophy.
6. **Screen layout**: `InventoryScreen` becomes a 2-tab layout (**Products**, **Categories**), replacing the current bottom-sheet category manager — the UX reasoning being that category management is a core, frequent task in inventory setup and deserves persistent, discoverable placement (via tabs) rather than being tucked behind a button, especially for non-technical users. This also matches kiosk's shell shape.
7. **Modifier group management UI**: since groups are now global, add a dedicated modifier-group management surface (3rd tab on `InventoryScreen`, alongside Products/Categories) for create/edit/soft-delete of groups + their options. The existing per-product screen (`/inventory/products/:id/modifiers`) changes from "create groups owned by this product" to **"attach/detach existing groups to this product"** (a multi-select list of all global groups). Creating a brand-new group from the per-product screen deep-links to the global management tab.
8. **Role gating**: reuse mobile's existing `UserEntity.isAdminOrSupervisor` (`lib/features/auth/entities/user_entity.dart:22`) to hide Add/Edit/toggle-availability/toggle-active/attach-modifier-group controls from non-admin/supervisor users, mirroring kiosk. Navigation to the Inventory screen itself stays ungated.

## Schema changes (`lib/core/database/tables/`)

- **`products_table.dart`**: drop `price` column (after migration backfill).
- **New `product_variants_table.dart`**: `id`, `productId` (FK → products), `name` (text), `price` (real), `isDefault` (bool, default false), `isActive` (bool, default true).
- **`modifier_groups_table.dart`**: remove `productId` FK. Becomes: `id`, `name`, `isRequired` (bool), `maxSelections` (int), `isActive` (bool, default true — new column, needed for soft-delete per decision 5).
- **New `product_modifier_groups_table.dart`**: junction table — `id`, `productId` (FK → products), `modifierGroupId` (FK → modifier_groups), unique constraint on `(productId, modifierGroupId)`.
- **`modifier_options_table.dart`**: add `isActive` (bool, default true — new column, for soft-delete per decision 5). Otherwise unchanged (`id`, `groupId`, `name`, `additionalPrice`).
- **`product_groups_table.dart`** (categories): unchanged — `isActive` already exists and becomes the sole "delete" mechanism; the "block delete if has products" guard is removed since there's no more hard delete.

### Migration

Bump the drift schema version and write a migration step that, in order:
1. Creates `product_variants`, `product_modifier_groups` tables; adds `isActive` to `modifier_groups` and `modifier_options`.
2. Backfills: for every existing product, insert one `ProductVariant` row using that product's current `price`, `isDefault: true`, `isActive: true`.
3. Backfills: for every existing `modifier_groups` row (currently has a `productId`), insert a corresponding `product_modifier_groups` row linking that group to its original product, and set `isActive: true` on the group.
4. Drops `products.price` and `modifier_groups.productId`.

## DAO changes (`lib/core/database/daos/products_dao.dart`)

- Remove: `deleteProduct`, `deleteProductGroup`, `deleteModifierGroup`, `deleteModifierOption` (and their cascading-delete transaction logic) — no longer called by anything once the UI is updated.
- Add: variant CRUD (`getVariantsForProduct`, `insertVariant`, `updateVariant` incl. default-reassignment, `toggleVariantActive`), modifier-group CRUD against the new global shape (`getAllModifierGroups`, `createModifierGroup`, `updateModifierGroup`, `toggleModifierGroupActive`), junction-table methods (`getModifierGroupsForProduct` via join, `attachModifierGroupToProduct`, `detachModifierGroupFromProduct`), `toggleModifierOptionActive`.
- Update: `getAllProducts`/`getProductById` to no longer select `price` directly — pricing now comes from the product's variants (default variant's price used for grid display).
- Update: category methods — `deleteProductGroup` removed; existing `updateProductGroup` (already supports `isActive`) becomes the only "remove a category" path.

## Screens & navigation

- **`inventory_screen.dart`**: rework into a `TabBar`/`TabBarView` with **Products**, **Categories**, **Modifier Groups** tabs (matching kiosk's coded-but-hidden 3-tab shape, except the 3rd tab is fully functional here). Remove `_ManageCategoriesSheet`.
- **New `categories_tab.dart`**: category grid/list, Add/Edit dialog (existing `category_form_dialog.dart` reused), toggle-active action replacing the delete button.
- **New `modifier_groups_management_screen.dart`** (or tab content): global list of modifier groups with expand-to-see-options, Add Group / Edit Group / toggle-active-group, Add Option / Edit Option / toggle-active-option — reuses `modifier_group_form_dialog.dart` and `modifier_option_form_dialog.dart`.
- **`modifier_groups_screen.dart`** (per-product, at `/inventory/products/:id/modifiers`): rework from "create/edit groups for this product" to a checklist of all active global groups with attach/detach toggles for this specific product. A "create new group" affordance routes to the global management tab/screen instead of creating inline.
- **`product_form_dialog.dart`**: add a variants editor section (rows of name/price/isDefault/isActive with add/remove), validation mirrored from kiosk: at least one active variant, unique case-insensitive names, price ≥ 0.01, exactly one default with auto-reassignment when the current default is removed/disabled. Remove the flat `price` field.
- Remove delete buttons/confirm-dialogs for products and categories from `inventory_screen.dart`; availability toggle remains the only per-product action besides Edit/Modifiers.

## State (Riverpod, `lib/features/inventory/state/`)

- **`inventory_notifier.dart`**: `InventoryState`/`InventoryProduct` no longer carry a flat `price`; product display price is derived from its default (or first active) variant. `deleteProduct`/`deleteCategory` methods removed. Add `toggleVariantActive`, `saveVariants` orchestration (create/update/soft-disable) analogous to kiosk's `InventoryProductsNotifier.save`.
- **`modifier_groups_notifier.dart`**: restructure around the global shape — a provider for "all global modifier groups + their options" (for the management tab) and a separate provider/method for "groups attached to product X" (for the per-product attach screen) plus attach/detach actions. `deleteGroup`/`deleteOption` become `toggleGroupActive`/`toggleOptionActive`.

## Business rules carried over from kiosk

- Variant rules: ≥1 active variant required to save a product; unique case-insensitive variant names; price ≥ 0.01; exactly one default, auto-reassigned if removed/disabled.
- Category: name required; toggling inactive doesn't require the "no products attached" guard anymore (nothing is deleted, so no orphan risk).
- Modifier group/option toggling replaces deletion; attaching/detaching a group to a product is independent of the group's own active state changes elsewhere.
- Role gating: `isAdminOrSupervisor` hides Add/Edit/toggle-active/toggle-availability/attach-detach controls; screen navigation itself is ungated.

## CSV importer impact (`lib/core/csv/products_csv_importer.dart`)

The importer currently writes a flat `price` per row directly onto the product. It must be updated to create one default `ProductVariant` (isDefault: true, isActive: true) per imported product using that row's price value, rather than writing to a `products.price` column that no longer exists. No changes to the CSV column format itself (still `group_name, product_name, price, is_available, image_url, sort_order`).

## Out of scope

- No backend/network/sync layer for mobile — this is purely local schema + UI/UX restructuring.
- No stock/quantity/low-stock-threshold tracking — neither app has this today; not part of this alignment effort.
- No changes to kiosk itself (kiosk is the reference model being matched, not being modified).
