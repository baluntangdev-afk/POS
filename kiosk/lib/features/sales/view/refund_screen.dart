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
import '../../../utils/decimal_formatter.dart';
import '../../../utils/decimal_rounding.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/windows_scaffold.dart';
import '../state/refund_notifier.dart';

class RefundScreen extends HookConsumerWidget {
  const RefundScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(refundProvider(receiptId), (previous, next) async {
      if (next case AsyncError(:final error)) {
        await showNetworkErrorDialog(context, error: error);

        if (context.mounted && context.canPop()) {
          context.pop();
        } else if (context.mounted) {
          const TransactionsRoute().go(context);
        }
      }
    });

    final isLoading = ref.watch(refundProvider(receiptId).select((it) => it.isLoading));

    return WindowsScaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: const _TopAppBar(),
      ),
      backgroundColor: ColorSet.background,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ResponsiveBuilder(
                kiosk: (context) => _LandscapeLayout(receiptId: receiptId),
                tablet: (context) => _LandscapeLayout(receiptId: receiptId),
                phone: (context) => _PortraitLayout(receiptId: receiptId),
              ),
    );
  }
}

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

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.responsive.value(kiosk: 120, tablet: 90, phone: 70),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorSet.secondary.withValues(alpha: 0.85),
            ColorSet.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.arrow_back_ios,
              color: ColorSet.light,
              size: context.responsive.value(kiosk: 48, tablet: 32, phone: 24),
            ),
          ),
          Expanded(
            child: Text(
              'Process Refund',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 36, tablet: 28, phone: 20),
                fontWeight: FontWeight.w600,
                color: ColorSet.light,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Gap(context.responsive.value(kiosk: 80, tablet: 56, phone: 40)),
        ],
      ),
    );
  }
}

class _ItemSelectionView extends ConsumerWidget {
  const _ItemSelectionView({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      margin: EdgeInsets.all(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Items to Refund',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(refundProvider(receiptId).notifier).toggleAllItemsSelection();
                  },
                  child: Text(
                    selectedQuantities.length == allItems.length ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 14),
                      color: ColorSet.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: mainItemsWithAddOns.length,
              separatorBuilder: (context, index) {
                return Divider(
                  height: context.responsive.value(kiosk: 30, tablet: 20, phone: 16),
                  thickness: 0.5,
                );
              },
              itemBuilder: (context, index) {
                final (:mainItem, :addOns) = mainItemsWithAddOns[index];
                final selectedQuantity = selectedQuantities[mainItem.id];
                final isSelected = selectedQuantity != null;

                return InkWell(
                  onTap: () {
                    ref
                        .read(refundProvider(receiptId).notifier)
                        .toggleItemSelection(item: mainItem, isSelected: isSelected);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                      horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            ref
                                .read(refundProvider(receiptId).notifier)
                                .toggleItemSelection(item: mainItem, isSelected: !(value ?? false));
                          },
                        ),
                        Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mainItem.description,
                                style: TextStyle(
                                  fontSize: context.responsive.value(
                                    kiosk: 30,
                                    tablet: 20,
                                    phone: 14,
                                  ),
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              if (isSelected && mainItem.quantity > 1) ...[
                                const Gap(8),
                                Row(
                                  children: [
                                    _QuantityButton(
                                      icon: Icons.remove,
                                      foregroundColor: ColorSet.secondary,
                                      backgroundColor: ColorSet.secondary.withValues(alpha: 0.2),
                                      onTap: () {
                                        ref
                                            .read(refundProvider(receiptId).notifier)
                                            .changeQuantity(
                                              item: mainItem,
                                              quantity: selectedQuantity - 1,
                                            );
                                      },
                                    ),
                                    Gap(context.responsive.value(kiosk: 24, tablet: 18, phone: 12)),
                                    Text(
                                      '$selectedQuantity',
                                      style: TextStyle(
                                        fontSize: context.responsive.value(
                                          kiosk: 20,
                                          tablet: 16,
                                          phone: 12,
                                        ),
                                      ),
                                    ),
                                    Gap(context.responsive.value(kiosk: 24, tablet: 18, phone: 12)),
                                    _QuantityButton(
                                      icon: Icons.add,
                                      foregroundColor: ColorSet.light,
                                      backgroundColor: ColorSet.secondary,
                                      onTap: () {
                                        ref
                                            .read(refundProvider(receiptId).notifier)
                                            .changeQuantity(
                                              item: mainItem,
                                              quantity: selectedQuantity + 1,
                                            );
                                      },
                                    ),
                                    Gap(context.responsive.value(kiosk: 8, phone: 4)),
                                    Text(
                                      'of ${mainItem.quantity}',
                                      style: TextStyle(
                                        fontSize: context.responsive.value(
                                          kiosk: 18,
                                          tablet: 16,
                                          phone: 12,
                                        ),
                                        fontWeight: FontWeight.normal,
                                        color: ColorSet.text.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Qty: ${mainItem.quantity}',
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 20,
                                      tablet: 16,
                                      phone: 12,
                                    ),
                                    fontWeight: FontWeight.normal,
                                    color: ColorSet.text.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                              if (addOns.isNotEmpty) ...[
                                const Gap(4),
                                Text(
                                  'Add-ons: ${addOns.map((addOn) => addOn.description).join(', ')}',
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 20,
                                      tablet: 16,
                                      phone: 12,
                                    ),
                                    fontWeight: FontWeight.normal,
                                    color: ColorSet.text.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                              Text(
                                (mainItem.totalAmount +
                                        addOns.fold(
                                          Decimal.zero,
                                          (sum, addOn) => sum + addOn.totalAmount,
                                        ))
                                    .pesoFormatted,
                                style: TextStyle(
                                  fontSize: context.responsive.value(
                                    kiosk: 36,
                                    tablet: 24,
                                    phone: 16,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: ColorSet.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
        width: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: foregroundColor,
          size: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
        ),
      ),
    );
  }
}

class _RefundControlsView extends HookConsumerWidget {
  const _RefundControlsView({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formData = ref.watch(refundProvider(receiptId).select((it) => it.value?.formData));

    final reasonController = useTextEditingController(text: formData?.reason ?? '');

    final refundMethods = useMemoized(() {
      return <({String image, String name, bool enabled})>[
        (image: Assets.images.svg.icPaymentCash.path, name: 'Cash Refund', enabled: true),
        (image: Assets.images.svg.icPaymentCard.path, name: 'Card Refund', enabled: false),
        (image: Assets.images.svg.icPaymentQr.path, name: 'E-wallet Refund', enabled: false),
      ];
    });

    if (formData == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 0, tablet: 0, phone: 12),
        context.responsive.value(kiosk: 24, tablet: 16, phone: 0),
        context.responsive.value(kiosk: 24, tablet: 16, phone: 12),
        context.responsive.value(kiosk: 24, tablet: 16, phone: 12),
      ),
      padding: EdgeInsets.all(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextBoxFormField(
                      controller: reasonController,
                      label: 'Reason',
                      hint: 'Enter refund reason',
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                      ),
                      onChanged: (value) {
                        ref.read(refundProvider(receiptId).notifier).changeReason(value ?? '');
                      },
                    ),
                    Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                    Text(
                      'Refund Method',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    ...refundMethods.map((method) {
                      final isSelected = formData.refundMethod == method.name;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                        ),
                        child: GestureDetector(
                          onTap:
                              method.enabled
                                  ? () {
                                    ref
                                        .read(refundProvider(receiptId).notifier)
                                        .changeRefundMethod(method.name);
                                  }
                                  : null,
                          child: Opacity(
                            opacity: method.enabled ? 1.0 : 0.4,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsive.value(
                                  kiosk: 20,
                                  tablet: 16,
                                  phone: 12,
                                ),
                                horizontal: context.responsive.value(
                                  kiosk: 20,
                                  tablet: 16,
                                  phone: 12,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF2FCFF) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? ColorSet.secondary
                                          : ColorSet.dark.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    method.image,
                                    width: context.responsive.value(
                                      kiosk: 40,
                                      tablet: 32,
                                      phone: 24,
                                    ),
                                  ),
                                  Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                                  Expanded(
                                    child: Text(
                                      method.name,
                                      style: TextStyle(
                                        fontSize: context.responsive.value(
                                          kiosk: 28,
                                          tablet: 20,
                                          phone: 16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color:
                                        isSelected
                                            ? ColorSet.secondary
                                            : ColorSet.dark.withValues(alpha: 0.2),
                                    size: context.responsive.value(
                                      kiosk: 24,
                                      tablet: 20,
                                      phone: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    _SummarySection(receiptId: receiptId),
                    Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
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
    final data = ref.watch(refundProvider(receiptId).select((it) => it.value));

    if (data == null) return const SizedBox.shrink();

    final selectedQuantities = data.formData.selectedQuantities;
    final receipt = data.receipt;

    final refundAmount = selectedQuantities.entries.fold(Decimal.zero, (sum, entry) {
      final itemId = entry.key;
      final quantity = Decimal.fromInt(entry.value);
      final item = receipt.items.firstWhere((item) => item.id == itemId);
      final unitPrice = (item.totalAmount / Decimal.fromInt(item.quantity))
          .toDecimal(scaleOnInfinitePrecision: 2)
          .toPrecision(2);
      return sum + (unitPrice * quantity);
    });

    return Column(children: [_SummaryRow(label: 'Refund Amount', amount: refundAmount)]);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.amount});

  final String label;
  final Decimal amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 22, tablet: 18, phone: 14),
              color: ColorSet.dark,
            ),
          ),
          Text(
            amount.pesoFormatted,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 22, tablet: 18, phone: 14),
              color: ColorSet.secondary,
              fontWeight: FontWeight.w600,
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
        final message =
            lackingData.length == 1
                ? 'Please provide ${lackingData.first}.'
                : 'Please provide the following:\n• ${lackingData.join('\n• ')}';

        return showMessageDialog(context, type: DialogType.error, message: message);
      }

      confirmAction.run(ref, (txn) {
        return ref.read(refundProvider(receiptId).notifier).confirmRefund();
      }).ignore();
    }

    ref.listen(confirmAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        await showNetworkErrorDialog(context, error: error);
        return;
      }

      if (next is MutationSuccess) {
        await showMessageDialog(
          context,
          type: DialogType.success,
          message: 'Refund has been processed.',
        );

        if (context.mounted && context.canPop()) {
          context.pop();
        }
      }
    });

    return GestureDetector(
      onTap: confirmStatus is! MutationPending ? () => submitForm() : null,
      child: Container(
        height: context.responsive.value(kiosk: 64, tablet: 56, phone: 48),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorSet.secondary.withValues(alpha: 0.85),
              ColorSet.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Confirm',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
              fontWeight: FontWeight.normal,
              color: ColorSet.light,
            ),
          ),
        ),
      ),
    );
  }
}
