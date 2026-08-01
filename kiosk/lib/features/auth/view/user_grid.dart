import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/login_roster_item.dart';
import '../state/login_roster_notifier.dart';
import 'user_tile.dart';

class UserGrid extends ConsumerWidget {
  const UserGrid({super.key, required this.onUserSelected});

  final void Function(LoginRosterItem user) onUserSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterState = ref.watch(loginRosterProvider);

    return rosterState.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: ColorSet.primary)),
          ),
      error:
          (error, stackTrace) => _RosterError(onRetry: () => ref.invalidate(loginRosterProvider)),
      data: (roster) {
        if (roster.isEmpty) {
          return const _RosterEmpty();
        }

        final tileWidth = context.responsive.value<double>(phone: 130, tablet: 150, kiosk: 170);
        final spacing = context.responsive.value<double>(phone: 12, tablet: 16, kiosk: 20);

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final user in roster)
              SizedBox(
                width: tileWidth,
                child: UserTile(user: user, onTap: () => onUserSelected(user)),
              ),
          ],
        );
      },
    );
  }
}

class _RosterError extends StatelessWidget {
  const _RosterError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: ColorSet.danger, size: 40),
          const SizedBox(height: 12),
          Text(
            'Could not load staff list. Check your connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: POSColors.textSecondary,
              fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: ColorSet.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _RosterEmpty extends StatelessWidget {
  const _RosterEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, color: POSColors.textTertiary, size: 40),
          const SizedBox(height: 12),
          Text(
            'No staff accounts are available. Please contact an administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: POSColors.textSecondary,
              fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
            ),
          ),
        ],
      ),
    );
  }
}
