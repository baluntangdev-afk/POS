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
import '../entities/sale.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_sheet.dart';
import 'reference_payment_sheet.dart';

/// A payment method the cashier can select, plus whatever detail was
/// captured for it (cash tendered, or a reference number).
class _PaymentSelection {
  final String method; // 'cash' | 'card' | 'ewallet'
  final double? cashReceived;
  final String? reference;

  const _PaymentSelection({required this.method, this.cashReceived, this.reference});

  double change(double total) => ((cashReceived ?? 0) - total).clamp(0.0, double.infinity);
}

class PaymentScreen extends HookConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderingData = ref.watch(
      orderingProvider.select((s) => s.value),
    );
    final cartState = orderingData?.sale;

    if (cartState == null || cartState.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Skip the redirect if this screen is no longer the active route (e.g. it's
        // mid-transition after a successful payment navigated away to the receipt).
        if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          context.go('/order');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selection = useState<_PaymentSelection?>(null);
    final isProcessing = useState(false);

    Future<void> pickMethod(String method, String displayName) async {
      if (method == 'cash') {
        final cashReceived = await showCashPaymentSheet(
          context,
          totalDue: cartState.total,
          initialCashReceived: selection.value?.method == 'cash'
              ? selection.value?.cashReceived
              : null,
        );
        if (cashReceived != null) {
          selection.value = _PaymentSelection(method: method, cashReceived: cashReceived);
        }
      } else {
        final reference = await showReferencePaymentSheet(
          context,
          methodLabel: displayName,
          totalDue: cartState.total,
          initialReference:
              selection.value?.method == method ? selection.value?.reference : null,
        );
        if (reference != null) {
          selection.value = _PaymentSelection(method: method, reference: reference);
        }
      }
    }

    Future<void> processPayment() async {
      final current = selection.value;
      if (current == null) return;

      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        context.go('/login');
        return;
      }

      isProcessing.value = true;
      try {
        final amountPaid =
            current.method == 'cash' ? (current.cashReceived ?? cartState.total) : cartState.total;

        final receipt = await ref.read(orderingProvider.notifier).confirmSale(
              cashierId: authState.user.id,
              method: current.method,
              amountPaid: amountPaid,
              reference: current.reference,
            );

        if (context.mounted) {
          context.go('/order/receipt/${receipt.id}');
          ref.read(orderingProvider.notifier).clearCart();
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Order total ──────────────────────────────────────────────────
          _OrderTotalCard(cartState: cartState),
          const Gap(AppSpacing.md),
          _VatSummaryCard(cartState: cartState),
          const Gap(AppSpacing.lg),

          // ── Payment method ────────────────────────────────────────────────
          Text('SELECT PAYMENT METHOD',
              style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 0.8)),
          const Gap(AppSpacing.sm),
          _PaymentMethodList(
            selection: selection.value,
            total: cartState.total,
            onTap: pickMethod,
          ),
          const Gap(AppSpacing.xxl),
        ],
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
          onPressed: (isProcessing.value || selection.value == null) ? null : processPayment,
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

// ── Order total card ─────────────────────────────────────────────────────────

class _OrderTotalCard extends StatelessWidget {
  final Sale cartState;
  const _OrderTotalCard({required this.cartState});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
            child: Column(
              children: [
                Text(
                  'Order Total',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Gap(4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'PHP ${cartState.total.toStringAsFixed(2)}',
                    style: AppTextStyles.displayLg.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── VAT breakdown ─────────────────────────────────────────────────────────────

class _VatSummaryCard extends StatelessWidget {
  final Sale cartState;
  const _VatSummaryCard({required this.cartState});

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, double amount})>[
      (label: 'VATable Sales', amount: cartState.vatableAmount),
      if (cartState.vatExemptSales > 0)
        (label: 'VAT-Exempt Sales', amount: cartState.vatExemptSales),
      (label: 'VAT', amount: cartState.vatAmount),
      if (cartState.totalDiscount > 0) (label: 'Discount', amount: -cartState.totalDiscount),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.label,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                Text(
                  'PHP ${r.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Payment method list ────────────────────────────────────────────────────────

class _PaymentMethodList extends StatelessWidget {
  final _PaymentSelection? selection;
  final double total;
  final void Function(String method, String displayName) onTap;

  const _PaymentMethodList({
    required this.selection,
    required this.total,
    required this.onTap,
  });

  static const _methods = [
    ('cash', 'Cash Payment', Icons.payments_rounded),
    ('card', 'Card', Icons.credit_card_rounded),
    ('ewallet', 'E-Wallet', Icons.account_balance_wallet_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _methods.length; i++) ...[
          if (i > 0) const Gap(AppSpacing.sm),
          _PaymentMethodCard(
            method: _methods[i].$1,
            label: _methods[i].$2,
            icon: _methods[i].$3,
            selection: selection,
            total: total,
            onTap: onTap,
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String method;
  final String label;
  final IconData icon;
  final _PaymentSelection? selection;
  final double total;
  final void Function(String method, String displayName) onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.label,
    required this.icon,
    required this.selection,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selection?.method == method;
    final isEnabled = selection == null || isSelected;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            onTap: isEnabled ? () => onTap(method, label) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        if (isSelected && method == 'cash') ...[
                          const Gap(2),
                          Text(
                            'PHP ${(selection!.cashReceived ?? 0).toStringAsFixed(2)}  ·  '
                            'Change: PHP ${selection!.change(total).toStringAsFixed(2)}',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ],
                        if (isSelected && method != 'cash') ...[
                          const Gap(2),
                          Text(
                            'Ref: ${selection!.reference}',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
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
