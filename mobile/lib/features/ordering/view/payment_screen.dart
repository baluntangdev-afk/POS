import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/cart_state.dart';
import '../state/ordering_notifier.dart';

class PaymentScreen extends HookConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(
      orderingProvider.select((s) => s.value),
    );

    if (cartState == null || cartState.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/order');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedMethod = useState('cash');
    final tenderController = useTextEditingController();
    final referenceController = useTextEditingController();
    final isProcessing = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    Future<void> processPayment() async {
      if (!formKey.currentState!.validate()) return;

      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        context.go('/login');
        return;
      }

      isProcessing.value = true;
      try {
        final tender = selectedMethod.value == 'cash'
            ? (double.tryParse(tenderController.text) ?? cartState.total)
            : cartState.total;

        await ref.read(orderingProvider.notifier).confirmSale(
              cashierId: authState.user.id,
              cashierName: authState.user.name,
              method: selectedMethod.value,
              amountPaid: tender,
              reference: selectedMethod.value != 'cash' &&
                      referenceController.text.trim().isNotEmpty
                  ? referenceController.text.trim()
                  : null,
            );

        if (context.mounted) {
          context.go('/order/receipt');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Order summary card ────────────────────────────────────────
            _SummaryCard(cartState: cartState),
            const Gap(AppSpacing.lg),

            // ── Sale type ─────────────────────────────────────────────────
            Text('ORDER TYPE',
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary, letterSpacing: 0.8)),
            const Gap(AppSpacing.sm),
            _SaleTypeSelector(
              selected: cartState.saleType,
              onChanged: (t) =>
                  ref.read(orderingProvider.notifier).setSaleType(t),
            ),
            const Gap(AppSpacing.lg),

            // ── Payment method ────────────────────────────────────────────
            Text('PAYMENT METHOD',
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary, letterSpacing: 0.8)),
            const Gap(AppSpacing.sm),
            _PaymentMethodSelector(
              selected: selectedMethod.value,
              onChanged: (m) {
                selectedMethod.value = m;
                tenderController.clear();
                referenceController.clear();
              },
            ),
            const Gap(AppSpacing.lg),

            // ── Method-specific input ─────────────────────────────────────
            if (selectedMethod.value == 'cash') ...[
              Text('CASH TENDERED',
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textSecondary, letterSpacing: 0.8)),
              const Gap(AppSpacing.sm),
              TextFormField(
                controller: tenderController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: 'PHP ',
                  hintText: cartState.total.toStringAsFixed(2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                style:
                    AppTextStyles.priceLg.copyWith(color: AppColors.primary),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v);
                  if (n == null) return 'Enter a valid amount';
                  if (n < cartState.total) {
                    return 'Tender must be at least PHP ${cartState.total.toStringAsFixed(2)}';
                  }
                  return null;
                },
                onChanged: (_) {},
              ),
              const Gap(AppSpacing.md),
              ListenableBuilder(
                listenable: tenderController,
                builder: (context, _) {
                  final tender =
                      double.tryParse(tenderController.text) ?? 0;
                  final ch = (tender - cartState.total)
                      .clamp(0.0, double.infinity);
                  return _ChangeRow(change: ch);
                },
              ),
            ] else ...[
              Text('REFERENCE / TRANSACTION NO.',
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textSecondary, letterSpacing: 0.8)),
              const Gap(AppSpacing.sm),
              TextFormField(
                controller: referenceController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. TXN-12345678',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) {
                  if (selectedMethod.value != 'cash' &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Please enter a reference number';
                  }
                  return null;
                },
              ),
            ],
            const Gap(AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).viewPadding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: FilledButton(
          onPressed: isProcessing.value ? null : processPayment,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: isProcessing.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  'Confirm Payment · PHP ${cartState.total.toStringAsFixed(2)}',
                  style: AppTextStyles.headingSm.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

// ── Summary card ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final CartState cartState;
  const _SummaryCard({required this.cartState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 18, color: AppColors.primary),
              const Gap(AppSpacing.sm),
              Text('Order Summary', style: AppTextStyles.headingSm),
            ],
          ),
          const Gap(AppSpacing.md),
          ...cartState.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.primary, fontSize: 10),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: AppTextStyles.bodyMd
                                  .copyWith(fontWeight: FontWeight.w500)),
                          if (item.modifiers.isNotEmpty)
                            Text(
                              item.modifiers
                                  .expand((g) => g.selected.map((o) => o.name))
                                  .join(', '),
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'PHP ${item.lineTotal.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
          const Divider(color: AppColors.divider),
          if (cartState.totalDiscount > 0) ...[
            _SummaryRow('Discount',
                '-PHP ${cartState.totalDiscount.toStringAsFixed(2)}',
                color: AppColors.warning),
            const Gap(4),
          ],
          _SummaryRow(
            'TOTAL',
            'PHP ${cartState.total.toStringAsFixed(2)}',
            bold: true,
            color: AppColors.primary,
            large: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  final Color? color;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.large = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: large
              ? AppTextStyles.headingSm
              : AppTextStyles.bodyMd.copyWith(
                  color: color ?? AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
        ),
        Text(
          value,
          style: large
              ? AppTextStyles.priceMd.copyWith(color: color ?? AppColors.primary)
              : AppTextStyles.bodyMd.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Sale type selector ─────────────────────────────────────────────────────────

class _SaleTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SaleTypeSelector({required this.selected, required this.onChanged});

  static const _types = [
    ('dine_in', 'Dine In', Icons.restaurant_rounded),
    ('take_out', 'Take Out', Icons.takeout_dining_rounded),
    ('delivery', 'Delivery', Icons.delivery_dining_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((t) {
        final (key, label, icon) = t;
        final isSel = selected == key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 22,
                      color: isSel
                          ? Colors.white
                          : AppColors.textSecondary),
                  const Gap(4),
                  Text(label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSel
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSel
                            ? FontWeight.w700
                            : FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Payment method selector ────────────────────────────────────────────────────

class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _methods = [
    ('cash', 'Cash', Icons.payments_rounded),
    ('card', 'Card', Icons.credit_card_rounded),
    ('ewallet', 'E-Wallet', Icons.account_balance_wallet_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _methods.map((m) {
        final (key, label, icon) = m;
        final isSel = selected == key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: isSel
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 22,
                      color: isSel
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const Gap(4),
                  Text(label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSel
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSel
                            ? FontWeight.w700
                            : FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Change row ─────────────────────────────────────────────────────────────────

class _ChangeRow extends StatelessWidget {
  final double change;
  const _ChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: change > 0
            ? AppColors.successLight
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Change',
              style: AppTextStyles.headingSm.copyWith(
                  color: change > 0
                      ? AppColors.success
                      : AppColors.textSecondary)),
          Text(
            'PHP ${change.toStringAsFixed(2)}',
            style: AppTextStyles.priceLg.copyWith(
              color: change > 0 ? AppColors.success : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
