import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/entities/user_entity.dart';
import '../../auth/state/auth_providers.dart';
import '../../ordering/use_cases/void_sale.dart';

class VoidTransactionDialog extends HookConsumerWidget {
  const VoidTransactionDialog({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.totalAmount,
  });

  final int saleId;
  final String invoiceNumber;
  final double totalAmount;

  static Future<bool> show(
    BuildContext context, {
    required int saleId,
    required String invoiceNumber,
    required double totalAmount,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => VoidTransactionDialog(
            saleId: saleId,
            invoiceNumber: invoiceNumber,
            totalAmount: totalAmount,
          ),
        ) ??
        false;
  }

  static const _maxPinLength = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reasonCtrl = useTextEditingController();
    final selectedAuthorizer = useState<UserEntity?>(null);
    final pin = useState('');
    final isLoading = useState(false);
    final error = useState<String?>(null);
    final authorizersAsync = ref.watch(authorizersProvider);

    void appendDigit(String digit) {
      if (pin.value.length < _maxPinLength) pin.value += digit;
    }

    void deleteDigit() {
      if (pin.value.isNotEmpty) {
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    Future<void> confirmVoid() async {
      if (isLoading.value) return;

      final reason = reasonCtrl.text.trim();
      final authorizer = selectedAuthorizer.value;

      final missing = <String>[];
      if (reason.isEmpty) missing.add('void reason');
      if (authorizer == null) missing.add('authorizer');
      if (pin.value.length < 4) missing.add('PIN (min. 4 digits)');

      if (missing.isNotEmpty) {
        error.value = 'Please provide: ${missing.join(', ')}.';
        return;
      }

      isLoading.value = true;
      error.value = null;

      final authorized = await ref
          .read(authNotifierProvider.notifier)
          .verifyPinForUser(authorizer!.id, pin.value);

      if (!authorized) {
        isLoading.value = false;
        pin.value = '';
        error.value = 'Invalid PIN or insufficient permissions';
        return;
      }

      await ref.read(voidSaleProvider)(saleId: saleId, reason: reason);
      isLoading.value = false;
      if (context.mounted) Navigator.of(context).pop(true);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.block_rounded, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Void Transaction',
                            style: AppTextStyles.headingSm.copyWith(color: AppColors.error)),
                        Text(
                          '$invoiceNumber  ·  ₱${totalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'This action cannot be undone. The transaction will be permanently cancelled.',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('REASON FOR VOID',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Enter void reason...'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('SUPERVISOR AUTHORIZATION',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    authorizersAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Failed to load authorizers: $e',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                      data: (authorizers) => DropdownButtonFormField<UserEntity>(
                        initialValue: selectedAuthorizer.value,
                        decoration: const InputDecoration(labelText: 'Authorizer'),
                        items: authorizers
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text('${u.name} (${u.role})')))
                            .toList(),
                        onChanged: (u) => selectedAuthorizer.value = u,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PinDisplay(pin: pin.value, maxLength: _maxPinLength),
                    const SizedBox(height: AppSpacing.md),
                    _PinPad(onDigit: appendDigit, onDelete: deleteDigit),
                    if (error.value != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(error.value!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading.value ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLoading.value ? null : confirmVoid,
                      icon: isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.block_rounded, size: 16),
                      label: Text(isLoading.value ? 'Voiding...' : 'Void Transaction'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDisplay extends StatelessWidget {
  const _PinDisplay({required this.pin, required this.maxLength});

  final String pin;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLength, (index) {
          final isFilled = index < pin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppColors.error : Colors.transparent,
              border: Border.all(
                color: isFilled ? AppColors.error : AppColors.border,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    const btnSize = AppSpacing.touchPreferred;

    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final digit in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PinButton(label: digit, size: btnSize, onTap: () => onDigit(digit)),
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: btnSize + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _PinButton(label: '0', size: btnSize, onTap: () => onDigit('0')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _PinDeleteButton(size: btnSize, onTap: onDelete),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.label, required this.size, required this.onTap});

  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Center(
            child: Text(label,
                style: AppTextStyles.headingSm.copyWith(fontSize: size * 0.35)),
          ),
        ),
      ),
    );
  }
}

class _PinDeleteButton extends StatelessWidget {
  const _PinDeleteButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Icon(Icons.backspace_outlined, color: AppColors.error, size: size * 0.38),
        ),
      ),
    );
  }
}
