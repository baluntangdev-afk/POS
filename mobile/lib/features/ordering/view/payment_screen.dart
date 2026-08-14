import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/features/ordering/view/receipt_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../settings/state/store_info_notifier.dart';
import '../../cashier_accounting/daily_report/state/daily_report_notifier.dart';
import '../../cashier_accounting/x_reading/state/x_reading_notifier.dart';
import '../../cashier_accounting/z_reading/state/z_reading_notifier.dart';
import '../../transactions/state/transactions_notifier.dart';
import '../entities/line_item.dart';
import '../entities/sale.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_sheet.dart';
import 'reference_payment_sheet.dart';

/// A payment method as configured in Settings, resolved to an internal id
/// used by the rest of the app. Methods labelled 'Cash' map to the 'cash'
/// id so downstream tendered-amount/change logic keeps working; everything
/// else keeps its configured label as the id (routed through the reference
/// payment flow).
IconData _iconForLabel(String label) => switch (label) {
  'Cash' => Icons.payments_rounded,
  'GCash' => Icons.account_balance_wallet_rounded,
  _ => Icons.credit_card_rounded,
};

String _methodIdForLabel(String label) => label == 'Cash' ? 'cash' : label;

/// A payment method the cashier can select, plus whatever detail was
/// captured for it (cash tendered, or a reference number).
class _PaymentSelection {
  final String method; // 'cash' | 'card' | 'ewallet'
  final double? cashReceived;
  final String? reference;

  const _PaymentSelection({
    required this.method,
    this.cashReceived,
    this.reference,
  });

  double change(double total) =>
      ((cashReceived ?? 0) - total).clamp(0.0, double.infinity);
}

class PaymentScreen extends HookConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderingData = ref.watch(orderingProvider.select((s) => s.value));
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

    final paymentMethods = ref.watch(paymentMethodsProvider);
    final selection = useState<_PaymentSelection?>(null);
    final isProcessing = useState(false);

    Future<void> pickMethod(String method, String displayName) async {
      if (method == 'cash') {
        final cashReceived = await showCashPaymentSheet(
          context,
          totalDue: cartState.total,
          initialCashReceived:
              selection.value?.method == 'cash'
                  ? selection.value?.cashReceived
                  : null,
        );
        if (cashReceived != null) {
          selection.value = _PaymentSelection(
            method: method,
            cashReceived: cashReceived,
          );
        }
      } else {
        final reference = await showReferencePaymentSheet(
          context,
          methodLabel: displayName,
          totalDue: cartState.total,
          initialReference:
              selection.value?.method == method
                  ? selection.value?.reference
                  : null,
        );
        if (reference != null) {
          selection.value = _PaymentSelection(
            method: method,
            reference: reference,
          );
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
            current.method == 'cash'
                ? (current.cashReceived ?? cartState.total)
                : cartState.total;

        final receipt = await ref
            .read(orderingProvider.notifier)
            .confirmSale(
              cashierId: authState.user.id,
              method: current.method,
              amountPaid: amountPaid,
              reference: current.reference,
            );

        ref.invalidate(transactionsProvider);
        ref.invalidate(xReadingProvider);
        ref.invalidate(zReadingProvider);
        ref.invalidate(dailyReportProvider);

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
          // ── Order summary ────────────────────────────────────────────────
          _OrderSummaryCard(cartState: cartState),
          const Gap(AppSpacing.lg),

          // ── Payment method ────────────────────────────────────────────────
          Text(
            'SELECT PAYMENT METHOD',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Gap(AppSpacing.sm),
          paymentMethods.when(
            data:
                (methods) => _PaymentMethodList(
                  methods: methods,
                  selection: selection.value,
                  total: cartState.total,
                  onTap: pickMethod,
                ),
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error: (error, _) => _PaymentMethodsError(error: error),
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
          onPressed:
              (isProcessing.value || selection.value == null)
                  ? null
                  : processPayment,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
          child:
              isProcessing.value
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    'Confirm Payment · PHP ${cartState.total.toStringAsFixed(2)}',
                    style: AppTextStyles.headingSm.copyWith(
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }
}

// ── Order summary card (line items + VAT breakdown + total) ────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final Sale cartState;

  const _OrderSummaryCard({required this.cartState});

  @override
  Widget build(BuildContext context) {
    final vatRows = <({String label, double amount})>[
      (label: 'VATable Sales', amount: cartState.vatableAmount),
      if (cartState.vatExemptSales > 0)
        (label: 'VAT-Exempt Sales', amount: cartState.vatExemptSales),
      (label: 'VAT', amount: cartState.vatAmount),
      if (cartState.totalDiscount > 0)
        (label: 'Discount', amount: -cartState.totalDiscount),
    ];

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in cartState.items) _SummaryLineRow(item: item),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          for (final r in vatRows) _VatRow(label: r.label, amount: r.amount),
          const Gap(AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Due',
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'PHP ${cartState.total.toStringAsFixed(2)}',
                    style: AppTextStyles.displayMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLineRow extends StatelessWidget {
  final LineItem item;

  const _SummaryLineRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name =
        item.variantName.isEmpty
            ? item.productName
            : '${item.productName} (${item.variantName})';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$name ×${item.quantity}',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'PHP ${item.lineTotal.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _VatRow extends StatelessWidget {
  final String label;
  final double amount;

  const _VatRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            'PHP ${amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment method list ────────────────────────────────────────────────────────

class _PaymentMethodList extends StatelessWidget {
  final List<PaymentMethodsTableData> methods;
  final _PaymentSelection? selection;
  final double total;
  final void Function(String method, String displayName) onTap;

  const _PaymentMethodList({
    required this.methods,
    required this.selection,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return const _PaymentMethodsEmpty();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = AppSpacing.sm;
        final cardWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final m in methods)
              SizedBox(
                width: cardWidth,
                child: _PaymentMethodCard(
                  method: _methodIdForLabel(m.label),
                  label: m.label,
                  icon: _iconForLabel(m.label),
                  selection: selection,
                  total: total,
                  onTap: onTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PaymentMethodsEmpty extends StatelessWidget {
  const _PaymentMethodsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 32,
            color: AppColors.textSecondary,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'No payment methods configured',
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const Gap(4),
          Text(
            'Add one in Settings → Payment Methods before taking payment.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsError extends StatelessWidget {
  final Object error;

  const _PaymentMethodsError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
          const Gap(AppSpacing.sm),
          Text(
            'Failed to load payment methods',
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const Gap(4),
          Text(
            '$error',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

    String? caption;
    if (isSelected && method == 'cash') {
      caption =
          'PHP ${(selection!.cashReceived ?? 0).toStringAsFixed(2)} · '
          'Change PHP ${selection!.change(total).toStringAsFixed(2)}';
    } else if (isSelected) {
      caption = 'Ref: ${selection!.reference}';
    }

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow:
              isSelected
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: isEnabled ? () => onTap(method, label) : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        label,
                        style: AppTextStyles.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                      ),
                      if (caption != null) ...[
                        const Gap(2),
                        Text(
                          caption,
                          style: AppTextStyles.bodySm.copyWith(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
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
