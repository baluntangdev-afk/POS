# Ordering Screen — Order Panel Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing mini-cart panel and sticky cart bar with a unified `_OrderPanel` that shows all cart items inline-editable (qty, per-item order type, notes) and adapts between a persistent split panel (wide screens) and a bottom-sheet drawer (narrow screens).

**Architecture:** `LineItem` gains two new optional fields (`itemSaleType`, `notes`). A new `_OrderPanel` widget holds expanded-item state locally and calls existing `orderingProvider.notifier` methods. `_AdaptiveOrderingLayout` uses `LayoutBuilder` to choose between the split and FAB layouts at the 720 logical-pixel threshold.

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), `flutter_hooks`, `dart_mappable` (code-gen), `fast_immutable_collections`, `go_router`

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| **Modify** | `kiosk/lib/features/sales/entities/line_item.dart` | Add `itemSaleType` + `notes` fields |
| **Regenerated** | `kiosk/lib/features/sales/entities/line_item.mapper.dart` | Auto-generated — do not edit |
| **Rewrite** | `kiosk/lib/features/sales/view/ordering_screen.dart` | All layout + panel widgets |

---

## Task 1 — Extend `LineItem` with `itemSaleType` and `notes`

**Files:**
- Modify: `kiosk/lib/features/sales/entities/line_item.dart`
- Regenerated: `kiosk/lib/features/sales/entities/line_item.mapper.dart`

- [ ] **Step 1: Add the two new fields**

Open `kiosk/lib/features/sales/entities/line_item.dart` and update the class. The full file after the change:

```dart
import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../utils/tax_calculator.dart';
import '../enums/sale_type.dart';
import 'discount.dart';
import 'selected_modifier.dart';
import 'selected_variant.dart';

part 'line_item.mapper.dart';

@MappableClass()
class LineItem with LineItemMappable {
  const LineItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.variant,
    required this.modifiers,
    required this.categoryName,
    this.discount,
    this.itemSaleType,
    this.notes,
  });

  final String id;
  final int productId;
  final String productName;
  final String categoryName;
  final Uint8List productImage;
  final int quantity;
  final SelectedVariant variant;
  final IList<SelectedModifier> modifiers;
  final Discount? discount;
  final SaleType? itemSaleType;
  final String? notes;

  Decimal get grossAmount {
    final modifiersPrice = modifiers.fold(
      Decimal.zero,
      (total, modifier) => total + modifier.price,
    );
    return Decimal.fromInt(quantity) * (variant.price + modifiersPrice);
  }

  bool get isVatExempt => discount?.isVatExempt ?? false;

  Decimal get discountAmount => discount?.calculateAmount(grossAmount) ?? Decimal.zero;

  Decimal get totalAmount {
    if (isVatExempt) {
      final vatable = grossAmount.vatableAmount;
      return vatable - discountAmount;
    }
    return grossAmount - discountAmount;
  }
}
```

- [ ] **Step 2: Run build_runner to regenerate the mapper**

```bash
cd kiosk
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: Outputs `line_item.mapper.dart` with no errors. If you see a conflict prompt, the `--delete-conflicting-outputs` flag handles it automatically.

- [ ] **Step 3: Verify the build passes**

```bash
fvm dart analyze lib/features/sales/entities/line_item.dart
```

Expected: `No issues found!`

---

## Task 2 — Add small helper widgets to `ordering_screen.dart`

These are internal helpers used by `_OrderItemRow`. Add them at the bottom of `ordering_screen.dart` (after all existing code).

**Files:**
- Modify: `kiosk/lib/features/sales/view/ordering_screen.dart`

- [ ] **Step 1: Add `_QuantityStepper` and `_StepBtn`**

Append to the bottom of `ordering_screen.dart`:

```dart
// ── Quantity stepper (used inside _OrderItemRow) ──────────────────────────────
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.full),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? onDecrease : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: POSColors.textPrimary,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onIncrease, filled: true),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled
              ? ColorSet.primary
              : ColorSet.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: filled
              ? Colors.white
              : (enabled ? ColorSet.primary : POSColors.textDisabled),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `_SaleTypePill` and `_PillSegment`**

Append to the bottom of `ordering_screen.dart`:

```dart
// ── Per-item sale type pill toggle ────────────────────────────────────────────
class _SaleTypePill extends StatelessWidget {
  const _SaleTypePill({required this.selected, required this.onChanged});

  final SaleType? selected;
  final ValueChanged<SaleType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.full),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _PillSegment(
            label: 'Dine In',
            isSelected: selected == SaleType.dineIn,
            onTap: () => onChanged(
              selected == SaleType.dineIn ? null : SaleType.dineIn,
            ),
          ),
          _PillSegment(
            label: 'Take Out',
            isSelected: selected == SaleType.takeOut,
            onTap: () => onChanged(
              selected == SaleType.takeOut ? null : SaleType.takeOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: POSAnimation.fast,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? ColorSet.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(POSRadius.full),
            boxShadow: isSelected ? POSShadow.button : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : POSColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify analyze still passes**

```bash
fvm dart analyze lib/features/sales/view/ordering_screen.dart
```

Expected: No new errors (some warnings about unused old widgets are fine — they get removed in Task 6).

---

## Task 3 — Build `_OrderItemRow`

`_OrderItemRow` renders one cart item. It has a collapsed header (always visible) and an expanded controls section (visible only when `isExpanded == true`). It is a pure `HookWidget` — all state changes flow back via callbacks.

**Files:**
- Modify: `kiosk/lib/features/sales/view/ordering_screen.dart`

- [ ] **Step 1: Add the required import for `SaleType`**

At the top of `ordering_screen.dart`, confirm this import is present (add if missing):

```dart
import '../enums/sale_type.dart';
```

- [ ] **Step 2: Add `_OrderItemRow`**

Append to `ordering_screen.dart`:

```dart
// ── Single cart item row — collapsed + expanded ───────────────────────────────
class _OrderItemRow extends HookWidget {
  const _OrderItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onSaleTypeChanged,
    required this.onNotesChanged,
  });

  final LineItem item;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<SaleType?> onSaleTypeChanged;
  final ValueChanged<String> onNotesChanged;

  @override
  Widget build(BuildContext context) {
    final notesController = useTextEditingController(text: item.notes ?? '');
    final notesFocus = useFocusNode();

    // Save notes when focus leaves the field
    useEffect(() {
      void onFocusChange() {
        if (!notesFocus.hasFocus) onNotesChanged(notesController.text);
      }
      notesFocus.addListener(onFocusChange);
      return () => notesFocus.removeListener(onFocusChange);
    }, const []);

    // Keep controller in sync if the item is replaced externally
    useEffect(() {
      final newNotes = item.notes ?? '';
      if (notesController.text != newNotes && !notesFocus.hasFocus) {
        notesController.text = newNotes;
      }
      return null;
    }, [item.notes]);

    final modifierSummary = item.modifiers
        .expand((m) => m.options.map((o) => o.name))
        .join(', ');

    return AnimatedContainer(
      duration: POSAnimation.fast,
      decoration: BoxDecoration(
        color: isExpanded
            ? ColorSet.primary.withValues(alpha: 0.06)
            : POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(
          color: isExpanded ? ColorSet.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Collapsed header (always visible) ──
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(POSRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isExpanded
                                ? ColorSet.primary
                                : POSColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: POSColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.itemSaleType != null)
                              _SaleTypeBadge(saleType: item.itemSaleType!),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                item.notes!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: POSColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (modifierSummary.isNotEmpty)
                              Text(
                                modifierSummary,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: POSColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.grossAmount.pesoFormatted,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ColorSet.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded controls ──
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: POSColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity + delete
                  Row(
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 11,
                          color: POSColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _QuantityStepper(
                        quantity: item.quantity,
                        onDecrease: () => onQuantityChanged(item.quantity - 1),
                        onIncrease: () => onQuantityChanged(item.quantity + 1),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(POSRadius.full),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Order type
                  const Text(
                    'ORDER TYPE',
                    style: TextStyle(
                      fontSize: 9,
                      color: POSColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SaleTypePill(
                    selected: item.itemSaleType,
                    onChanged: onSaleTypeChanged,
                  ),
                  const SizedBox(height: 10),

                  // Notes
                  const Text(
                    'NOTES',
                    style: TextStyle(
                      fontSize: 9,
                      color: POSColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesController,
                    focusNode: notesFocus,
                    onSubmitted: onNotesChanged,
                    style: const TextStyle(
                      fontSize: 12,
                      color: POSColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. no onions, extra rice...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: POSColors.textDisabled,
                        fontStyle: FontStyle.italic,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        borderSide: const BorderSide(color: POSColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        borderSide: const BorderSide(color: POSColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        borderSide: const BorderSide(
                          color: ColorSet.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Small badge shown in collapsed state when itemSaleType is set
class _SaleTypeBadge extends StatelessWidget {
  const _SaleTypeBadge({required this.saleType});
  final SaleType saleType;

  @override
  Widget build(BuildContext context) {
    final isDineIn = saleType == SaleType.dineIn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isDineIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        saleType.displayName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDineIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze**

```bash
fvm dart analyze lib/features/sales/view/ordering_screen.dart
```

Expected: No errors on the newly added classes. Existing warnings about unused old widgets are acceptable at this stage.

---

## Task 4 — Build `_OrderPanel`

`_OrderPanel` is a `HookConsumerWidget` that holds the `selectedIndex` state and renders the full panel. It is used in both the split layout (with a bounded width) and wrapped in `_OrderPanelSheet`.

**Files:**
- Modify: `kiosk/lib/features/sales/view/ordering_screen.dart`

- [ ] **Step 1: Add `_OrderPanel` and `_CheckoutButton`**

Append to `ordering_screen.dart`:

```dart
// ── Order panel ───────────────────────────────────────────────────────────────
class _OrderPanel extends HookConsumerWidget {
  const _OrderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      orderingProvider.select(
        (it) => it.value?.sale.items ?? const IList.empty(),
      ),
    );
    final total = ref.watch(
      orderingProvider.select((it) => it.value?.sale.totalAmount),
    );
    final selectedIndex = useState<int?>(null);

    // Reset selection if the selected item is removed
    useEffect(() {
      final sel = selectedIndex.value;
      if (sel != null && sel >= items.length) selectedIndex.value = null;
      return null;
    }, [items.length]);

    void replaceItem(int index, LineItem updated) =>
        ref.read(orderingProvider.notifier).replaceLineItem(updated, index: index);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: ColorSet.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: POSColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorSet.primary,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Item list
          Expanded(
            child: items.isEmpty
                ? const _EmptyCartState()
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _OrderItemRow(
                        key: ValueKey(item.id),
                        item: item,
                        index: index,
                        isExpanded: selectedIndex.value == index,
                        onTap: () => selectedIndex.value =
                            selectedIndex.value == index ? null : index,
                        onRemove: () {
                          if (selectedIndex.value == index) selectedIndex.value = null;
                          ref
                              .read(orderingProvider.notifier)
                              .removeLineItem(index: index);
                        },
                        onQuantityChanged: (qty) =>
                            replaceItem(index, item.copyWith(quantity: qty)),
                        onSaleTypeChanged: (type) =>
                            replaceItem(index, item.copyWith(itemSaleType: type)),
                        onNotesChanged: (notes) => replaceItem(
                          index,
                          item.copyWith(notes: notes.isEmpty ? null : notes),
                        ),
                      );
                    },
                  ),
          ),

          // Total + Checkout
          if (items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: POSColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: POSColors.textSecondary,
                    ),
                  ),
                  if (total != null)
                    Text(
                      total.pesoFormatted,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ColorSet.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _CheckoutButton(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: POSGradient.primary,
        borderRadius: BorderRadius.circular(POSRadius.xxl),
        boxShadow: POSShadow.button,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(POSRadius.xxl),
        child: InkWell(
          borderRadius: BorderRadius.circular(POSRadius.xxl),
          onTap: () => const CartRoute().push<void>(context),
          child: const SizedBox(
            height: 48,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'View Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
fvm dart analyze lib/features/sales/view/ordering_screen.dart
```

Expected: No errors on new code.

---

## Task 5 — Build `_CartFab` and `_OrderPanelSheet`

These are used on narrow screens (< 720 logical px). The FAB shows item count + total. Tapping it opens `_OrderPanelSheet`, a modal bottom sheet wrapping `_OrderPanel`.

**Files:**
- Modify: `kiosk/lib/features/sales/view/ordering_screen.dart`

- [ ] **Step 1: Add `_CartFab`**

Append to `ordering_screen.dart`:

```dart
// ── Cart FAB — shown on narrow screens ───────────────────────────────────────
class _CartFab extends ConsumerWidget {
  const _CartFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:count, :total) = ref.watch(
      orderingProvider.select(
        (it) => (
          count: it.value?.sale.items.length ?? 0,
          total: it.value?.sale.totalAmount,
        ),
      ),
    );
    if (count <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _OrderPanelSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: POSGradient.primary,
          borderRadius: BorderRadius.circular(POSRadius.xxl),
          boxShadow: POSShadow.button,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Order ($count)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (total != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Text(
                total.pesoFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `_OrderPanelSheet`**

Append to `ordering_screen.dart`:

```dart
// ── Bottom-sheet wrapper around _OrderPanel ───────────────────────────────────
class _OrderPanelSheet extends StatelessWidget {
  const _OrderPanelSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(POSRadius.xl),
            ),
            boxShadow: POSShadow.elevated,
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: POSColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Expanded(child: _OrderPanel()),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Analyze**

```bash
fvm dart analyze lib/features/sales/view/ordering_screen.dart
```

Expected: No errors on new code.

---

## Task 6 — Build `_AdaptiveOrderingLayout`, update `OrderingScreen`, remove old widgets

This task wires everything together and removes `_MiniCartPanel`, `_StickyCartBar`, and `_CartButton`.

**Files:**
- Modify: `kiosk/lib/features/sales/view/ordering_screen.dart`

- [ ] **Step 1: Add `_AdaptiveOrderingLayout`**

Append to `ordering_screen.dart` (before the old layout classes — placement doesn't matter but keep it near the top for readability):

```dart
// ── Adaptive layout — splits or stacks based on available width ───────────────
class _AdaptiveOrderingLayout extends StatelessWidget {
  const _AdaptiveOrderingLayout();

  static const double _splitThreshold = 720;
  static const double _panelWidth = 300;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _splitThreshold;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _OrderingHeader(),
            Container(
              height: r.value<double>(kiosk: 64, tablet: 60, phone: 52),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
              ),
              child: const _CategoryChipRow(),
            ),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(child: _ProductGrid()),
                        SizedBox(
                          width: r.value(
                            kiosk: _panelWidth + 20,
                            tablet: _panelWidth.toDouble(),
                            phone: _panelWidth.toDouble(),
                          ),
                          child: const _OrderPanel(),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        const _ProductGrid(),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: const _CartFab(),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Update `OrderingScreen.build` to use `_AdaptiveOrderingLayout`**

Find and replace the `build` method of `OrderingScreen` (lines 29–39 in the original file):

```dart
class OrderingScreen extends ConsumerWidget {
  const OrderingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: const _AdaptiveOrderingLayout(),
    );
  }
}
```

- [ ] **Step 3: Remove `_MiniCartPanel`, `_StickyCartBar`, `_CartButton`, `_ViewCartButton`, `_MiniCartItemList`**

Delete the following classes entirely from `ordering_screen.dart` (they are replaced by `_OrderPanel`, `_CartFab`, `_CheckoutButton`):

- `_MiniCartPanel` (lines ~462–558)
- `_ViewCartButton` (lines ~606–645)
- `_MiniCartItemList` (lines ~647–706)
- `_StickyCartBar` (lines ~371–459)
- `_CartButton` (lines ~1079–1149)

Also delete `_KioskLayout`, `_LandscapeLayout`, and `_CategoriesList` — none are referenced after this change.

`_TabletLayout` is also no longer referenced — delete it. `_CategoryChipRow` and `_ProductGrid` are still used — keep them.

After deletion, `ordering_screen.dart` should contain only:
- `OrderingScreen`
- `_OrderingHeader` + `_HeaderBackButton`
- `_AdaptiveOrderingLayout`
- `_CategoryChipRow`
- `_ProductGrid` + `_LoadingState` + `_EmptyProductsState` + `_ProductCard`
- `_EmptyCartState`
- `_OrderPanel` + `_CheckoutButton`
- `_OrderItemRow` + `_SaleTypeBadge`
- `_CartFab` + `_OrderPanelSheet`
- `_QuantityStepper` + `_StepBtn`
- `_SaleTypePill` + `_PillSegment`

- [ ] **Step 4: Full analyze**

```bash
fvm dart analyze lib/features/sales/view/ordering_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Run the app and verify**

```bash
fvm flutter run -d windows
```

Verify:
1. Ordering screen opens without errors.
2. On a wide window (≥ 720px): product grid and order panel are side by side.
3. On a narrow window (< 720px): only the product grid shows; a "Order (N) | ₱xxx" FAB appears bottom-right once items are added.
4. Tapping the FAB opens the bottom sheet.
5. Tapping a product opens the `LineItemDialog`; confirming adds the item to the order panel.
6. Tapping an order item in the panel expands it to show qty stepper, Order Type pill, Notes field.
7. Changing qty updates the price in real time.
8. Selecting Dine In / Take Out shows a badge in the collapsed item row.
9. Typing notes and blurring saves the note; it appears in the collapsed summary.
10. Tapping the trash icon removes the item.
11. "View Cart" button navigates to the cart screen as before.
