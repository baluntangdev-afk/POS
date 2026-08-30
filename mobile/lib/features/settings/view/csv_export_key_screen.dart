import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/crypto/csv_encryption_key_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class CsvExportKeyScreen extends HookConsumerWidget {
  const CsvExportKeyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyStore = ref.watch(csvEncryptionKeyStoreProvider);
    final isVisible = useState(false);
    final version = useState(0); // bumped after regenerate to refresh useFuture

    final keyAsync = useFuture(
      useMemoized(keyStore.getOrCreate, [version.value]),
    );

    final key = keyAsync.data;

    Future<void> handleRegenerate() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Regenerate Export Key?'),
          content: const Text(
            'Existing .enc files cannot be decrypted with the new key. '
            'Make sure you have saved copies of any exports you need.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Regenerate'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await keyStore.regenerate();
      version.value++;
      isVisible.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New export key generated')),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CSV Export Key'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This 256-bit key decrypts your exported .enc report files. '
              'Share it with whoever needs to open the exports '
              '(e.g., via CyberChef, Python, or OpenSSL).',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (key == null && keyAsync.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (key != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isVisible.value ? key : '•' * 32,
                        style: AppTextStyles.bodySm
                            .copyWith(fontFamily: 'monospace', letterSpacing: 1.0),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isVisible.value ? Icons.visibility_off : Icons.visibility,
                      ),
                      tooltip: isVisible.value ? 'Hide key' : 'Show key',
                      onPressed: () => isVisible.value = !isVisible.value,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy key',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: key));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Key copied to clipboard')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate Key'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: handleRegenerate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
