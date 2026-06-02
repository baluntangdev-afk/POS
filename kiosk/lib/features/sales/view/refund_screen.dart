import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/decimal_rounding.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/windows_scaffold.dart';
import '../state/refund_notifier.dart';
import 'refund_authorization_dialog.dart';

class RefundScreen extends HookConsumerWidget {
  const RefundScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(refundProvider(receiptId), (previous, next) async {
      if (next case AsyncError(:final error)) {
        await showMessageDialog(
          context,
          type: DialogType.error,
          message: 'Failed to load items: $error',
        );
        if (context.mounted && context.canPop()) {
          context.pop();
        } else if (context.mounted) {
          const TransactionsRoute().go(context);
        }
      }
    });

    final isLoading = ref.watch(refundProvider(receiptId).select((it) => it.isLoading));

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          const _FlatHeader(title: 'Process Refund'),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColorSet.primary,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                : ResponsiveBuilder(
                    kiosk: (context) => _LandscapeLayout(receiptId: receiptId),
                    tablet: (context) => _LandscapeLayout(receiptId: receiptId),
                    phone: (context) => _LandscapeLayout(receiptId: receiptId),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Flat white header ─────────────────────────────────────────────────────────
class _FlatHeader extends StatelessWidget {
  const _FlatHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final height = r.value<double>(kiosk: 68, tablet: 60, phone: 52);
    final btnH = r.value<double>(kiosk: 44, tablet: 40, phone: 36);

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 24, tablet: 16, phone: 12),
      ),
      child: Row(
        children: [
          SizedBox(
            height: btnH,
            child: OutlinedButton.icon(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
              ),
              label: Text(
                'Back',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.primary,
                side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.6), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 20, tablet: 17, phone: 15),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          SizedBox(width: r.value<double>(kiosk: 90, tablet: 76, phone: 64)),
        ],
      ),
    );
  }
}

// ── Layouts ───────────────────────────────────────────────────────────────────
class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _ItemSelectionView(receiptId: receiptId)),
        Expanded(flex: 2, child: _RefundControlsView(receiptId: receiptId)),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 2, child: _ItemSelectionView(receiptId: receiptId)),
        Expanded(child: _RefundControlsView(receiptId: receiptId)),
      ],
    );
  }
}

// ── Item selection panel ──────────────────────────────────────────────────────
class _ItemSelectionView extends ConsumerWidget {
  const _ItemSelectionView({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final (:receipt, :selectedQuantities) = ref.watch(
      refundProvider(receiptId).select(
        (it) => (
          receipt: it.value?.receipt,
          selectedQuantities: it.value?.formData.selectedQuantities ?? const <String, int>{},
        ),
      ),
    );

    if (receipt == null) return const SizedBox.shrink();

    final allItems = receipt.items;
    final mainItemsWithAddOns = receipt.mainItemsWithAddOns;

    return Container(
      margin: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.value<double>(kiosk: 20, tablet: 16, phone: 14),
              vertical: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ColorSet.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(POSRadius.xs),
                        ),
                        child: const Icon(Icons.assignment_return_rounded, color: ColorSet.danger, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select Items to Refund',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                            fontWeight: FontWeight.w700,
                            color: POSColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(refundProvider(receiptId).notifier).toggleAllItemsSelection();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: ColorSet.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    selectedQuantities.length == allItems.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: r.value<double>(kiosk: 8, tablet: 6, phone: 4)),
              itemCount: mainItemsWithAddOns.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: POSColors.borderSubtle,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final (:mainItem, :addOns) = mainItemsWithAddOns[index];
                final selectedQuantity = selectedQuantities[mainItem.id];
                final isSelected = selectedQuantity != null;

                final totalAmount = mainItem.totalAmount +
                    addOns.fold(Decimal.zero, (sum, addOn) => sum + addOn.totalAmount);

                return Material(
                  color: isSelected
                      ? ColorSet.danger.withValues(alpha: 0.03)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(refundProvider(receiptId).notifier).toggleItemSelection(
                        item: mainItem,
                        isSelected: isSelected,
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                        horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: ColorSet.danger,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(POSRadius.xs),
                              ),
                              onChanged: (value) {
                                ref.read(refundProvider(receiptId).notifier).toggleItemSelection(
                                  item: mainItem,
                                  isSelected: !(value ?? false),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mainItem.description,
                                  style: TextStyle(
                                    fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                                    fontWeight: FontWeight.w600,
                                    color: POSColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                if (isSelected && mainItem.quantity > 1) ...[
                                  _RefundQuantityStepper(
                                    value: selectedQuantity,
                                    max: mainItem.quantity,
                                    onChanged: (qty) {
                                      ref
                                          .read(refundProvider(receiptId).notifier)
                                          .changeQuantity(item: mainItem, quantity: qty);
                                    },
                                    r: r,
                                  ),
                                ] else ...[
                                  Text(
                                    'Qty: ${mainItem.quantity}',
                                    style: TextStyle(
                                      fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                      color: POSColors.textTertiary,
                                    ),
                                  ),
                                ],
                                if (addOns.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Add-ons: ${addOns.map((a) => a.description).join(', ')}',
                                    style: TextStyle(
                                      fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                                      color: POSColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                          Text(
                            totalAmount.pesoFormatted,
                            style: TextStyle(
                              fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                              fontWeight: FontWeight.w700,
                              color: isSelected ? ColorSet.danger : POSColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundQuantityStepper extends StatelessWidget {
  const _RefundQuantityStepper({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.r,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    final btnSize = r.value<double>(kiosk: 28, tablet: 24, phone: 20);
    final textSize = r.value<double>(kiosk: 14, tablet: 13, phone: 12);

    return Row(
      children: [
        _StepBtn(
          icon: Icons.remove,
          color: ColorSet.danger,
          size: btnSize,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
        Text(
          '$value',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w700,
            color: POSColors.textPrimary,
          ),
        ),
        SizedBox(width: r.value<double>(kiosk: 5, tablet: 4, phone: 3)),
        Text(
          'of $max',
          style: TextStyle(fontSize: textSize - 1, color: POSColors.textTertiary),
        ),
        SizedBox(width: r.value<double>(kiosk: 8, tablet: 6, phone: 5)),
        _StepBtn(
          icon: Icons.add,
          color: ColorSet.danger,
          size: btnSize,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.color, required this.size, this.onTap});

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: onTap != null ? color.withValues(alpha: 0.1) : POSColors.borderStrong,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Icon(
            icon,
            color: onTap != null ? color : POSColors.textDisabled,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

// ── Refund controls panel ─────────────────────────────────────────────────────
class _RefundControlsView extends HookConsumerWidget {
  const _RefundControlsView({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final formData = ref.watch(refundProvider(receiptId).select((it) => it.value?.formData));
    final reasonController = useTextEditingController(text: formData?.reason ?? '');

    final refundMethods = useMemoized(() => <({String image, String name, bool enabled})>[
      (image: Assets.images.svg.icPaymentCash.path, name: 'Cash Refund', enabled: true),
      (image: Assets.images.svg.icPaymentCard.path, name: 'Card Refund', enabled: false),
      (image: Assets.images.svg.icPaymentQr.path, name: 'E-wallet Refund', enabled: false),
    ]);

    if (formData == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(
        r.value<double>(kiosk: 0, tablet: 0, phone: 12),
        r.value<double>(kiosk: 20, tablet: 16, phone: 12),
        r.value<double>(kiosk: 20, tablet: 16, phone: 12),
        r.value<double>(kiosk: 20, tablet: 16, phone: 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 14)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Reason field
                    TextBoxFormField(
                      controller: reasonController,
                      label: 'Reason for Refund',
                      hint: 'Enter refund reason',
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                      ),
                      onChanged: (value) {
                        ref.read(refundProvider(receiptId).notifier).changeReason(value ?? '');
                      },
                    ),
                    SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 14)),

                    // Refund method label
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ColorSet.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(POSRadius.xs),
                          ),
                          child: const Icon(Icons.payments_outlined, color: ColorSet.danger, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Refund Method',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                            fontWeight: FontWeight.w700,
                            color: POSColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),

                    // Refund method cards
                    ...refundMethods.map((method) {
                      final isSelected = formData.refundMethod == method.name;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: r.value<double>(kiosk: 10, tablet: 8, phone: 6),
                        ),
                        child: Opacity(
                          opacity: method.enabled ? 1.0 : 0.45,
                          child: AnimatedContainer(
                            duration: POSAnimation.fast,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ColorSet.danger.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(POSRadius.lg),
                              border: Border.all(
                                color: isSelected ? ColorSet.danger : POSColors.borderDefault,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(POSRadius.lg),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(POSRadius.lg),
                                onTap: method.enabled
                                    ? () {
                                        ref
                                            .read(refundProvider(receiptId).notifier)
                                            .changeRefundMethod(method.name);
                                      }
                                    : null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
                                    vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: r.value<double>(kiosk: 40, tablet: 34, phone: 28),
                                        height: r.value<double>(kiosk: 40, tablet: 34, phone: 28),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? ColorSet.danger.withValues(alpha: 0.1)
                                              : POSColors.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(POSRadius.sm),
                                        ),
                                        child: Center(
                                          child: SvgPicture.asset(
                                            method.image,
                                            width: r.value<double>(kiosk: 22, tablet: 18, phone: 15),
                                            colorFilter: isSelected
                                                ? const ColorFilter.mode(
                                                    ColorSet.danger,
                                                    BlendMode.srcIn,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method.name,
                                              style: TextStyle(
                                                fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? ColorSet.danger
                                                    : POSColors.textPrimary,
                                              ),
                                            ),
                                            if (!method.enabled)
                                              Text(
                                                'Coming soon',
                                                style: TextStyle(
                                                  fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                                                  color: POSColors.textTertiary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: POSAnimation.fast,
                                        width: r.value<double>(kiosk: 22, tablet: 20, phone: 18),
                                        height: r.value<double>(kiosk: 22, tablet: 20, phone: 18),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? ColorSet.danger : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected ? ColorSet.danger : POSColors.borderStrong,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 13,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),


                    // Summary
                    _SummarySection(receiptId: receiptId),
                    SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),

                    // Confirm button
                    _ConfirmButton(receiptId: receiptId),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final data = ref.watch(refundProvider(receiptId).select((it) => it.value));

    if (data == null) return const SizedBox.shrink();

    final selectedQuantities = data.formData.selectedQuantities;
    final receipt = data.receipt;

    if (selectedQuantities.isEmpty) return const SizedBox.shrink();

    final refundAmount = selectedQuantities.entries.fold(Decimal.zero, (sum, entry) {
      final itemId = entry.key;
      final quantity = Decimal.fromInt(entry.value);
      final item = receipt.items.firstWhere((item) => item.id == itemId);
      final unitPrice = (item.totalAmount / Decimal.fromInt(item.quantity))
          .toDecimal(scaleOnInfinitePrecision: 2)
          .toPrecision(2);
      return sum + (unitPrice * quantity);
    });

    return Container(
      padding: EdgeInsets.all(r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
      decoration: BoxDecoration(
        color: ColorSet.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: ColorSet.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Refund Amount',
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
              fontWeight: FontWeight.w600,
              color: POSColors.textPrimary,
            ),
          ),
          Text(
            refundAmount.pesoFormatted,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 20, tablet: 17, phone: 15),
              fontWeight: FontWeight.w800,
              color: ColorSet.danger,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends ConsumerWidget {
  const _ConfirmButton({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final confirmAction = RefundNotifier.confirmAction;
    final confirmStatus = ref.watch(confirmAction);

    Future<void> submitForm() async {
      final formData = ref.read(refundProvider(receiptId)).value?.formData;
      final lackingData = <String>[];

      if (formData?.selectedQuantities.isEmpty ?? true) {
        lackingData.add('at least one item to refund');
      }
      if (formData?.reason.trim().isEmpty ?? true) {
        lackingData.add('reason for the refund');
      }

      if (lackingData.isNotEmpty) {
        final message = lackingData.length == 1
            ? 'Please provide ${lackingData.first}.'
            : 'Please provide the following:\n• ${lackingData.join('\n• ')}';
        return showMessageDialog(context, type: DialogType.error, message: message);
      }

      if (!context.mounted) return;
      final authorized = await RefundAuthorizationDialog.show(context);
      if (!authorized || !context.mounted) return;

      confirmAction.run(ref, (txn) {
        return ref.read(refundProvider(receiptId).notifier).confirmRefund();
      }).ignore();
    }

    ref.listen(confirmAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        await showMessageDialog(
          context,
          type: DialogType.error,
          message: 'Failed to process refund: $error',
        );
        return;
      }
      if (next is MutationSuccess) {
        await showMessageDialog(
          context,
          type: DialogType.success,
          title: 'Refund Processed',
          message: 'The refund has been successfully processed.',
          primaryButtonText: 'Done',
          barrierDismissible: false,
        );
        if (context.mounted && context.canPop()) context.pop();
      }
    });

    final isPending = confirmStatus is MutationPending;
    final height = r.value<double>(kiosk: 60, tablet: 56, phone: 52);
    const radius = POSRadius.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPending ? POSColors.borderStrong : ColorSet.danger,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isPending
            ? null
            : [
                BoxShadow(
                  color: ColorSet.danger.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: !isPending ? () => submitForm() : null,
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPending)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isPending ? 'Processing...' : 'Confirm Refund',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                    fontWeight: FontWeight.w600,
                    color: isPending ? POSColors.textDisabled : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
