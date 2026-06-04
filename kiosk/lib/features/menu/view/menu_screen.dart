import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_bottom_sheet.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/windows_scaffold.dart';
import '../../users/repositories/user_repository.dart';
import '../entities/access.dart';
import '../enums/role.dart';
import '../state/access_notifier.dart';
import '../state/pos_terminal_notifier.dart';
import '../view/menu_grid.dart';
import '../view/register_pos_terminal_dialog.dart';

class MenuScreen extends HookConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider.select((it) => it.value ?? Access.unknown()));
    final isAndroid = context.breakpoint.isAndroid;
    final hasShownPosDialog = useRef(false);
    final hasShownUsersDialog = useRef(false);

    void checkAndShowPosDialog() {
      if (hasShownPosDialog.value) return;
      final posState = ref.read(posTerminalProvider);
      final accessState = ref.read(accessProvider);
      if (posState.isLoading || accessState.isLoading) return;
      if (!posState.hasError) return;

      hasShownPosDialog.value = true;
      final role = accessState.value?.role;
      final isAdmin = role == Role.admin || role == Role.supervisor;

      if (isAdmin) {
        showMessageDialog(
          context,
          title: 'No POS Terminal Assigned',
          message:
              'No POS terminal is assigned to this account. Register a new terminal or sign out.',
          type: DialogType.error,
          primaryButtonText: 'Register POS',
          secondaryButtonText: 'Sign Out',
          barrierDismissible: false,
          onPrimaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            showRegisterPosTerminalDialog(context, ref);
          },
          onSecondaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            const OnboardingRoute().go(context);
          },
        );
      } else {
        showMessageDialog(
          context,
          title: 'No POS Terminal Assigned',
          message:
              'This account does not have a POS terminal assigned. Please contact your administrator.',
          type: DialogType.error,
          primaryButtonText: 'Sign Out',
          barrierDismissible: false,
          onPrimaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            const OnboardingRoute().go(context);
          },
        );
      }
    }

    Future<void> checkAndShowUsersDialog() async {
      if (hasShownUsersDialog.value) return;

      final posState = ref.read(posTerminalProvider);
      final accessState = ref.read(accessProvider);

      if (posState.isLoading || posState.hasError) return;
      if (accessState.isLoading || accessState.hasError) return;

      final access = accessState.value!;
      if (access.role != Role.admin) return;

      hasShownUsersDialog.value = true;

      try {
        final repo = ref.read(userRepositoryProvider);
        final (_, total) = await repo.getUsers(limit: 2, page: 1);
        if (!context.mounted) return;
        if (total <= 1) {
          unawaited(showMessageDialog(
            context,
            title: 'No Employees Added',
            message:
                'No employee accounts have been set up yet. '
                'Add at least one employee before operating the system.',
            type: DialogType.warning,
            primaryButtonText: 'Add Employee',
            secondaryButtonText: 'Sign Out',
            barrierDismissible: false,
            onPrimaryPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              const UserManagementRoute().push<void>(context);
            },
            onSecondaryPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              const OnboardingRoute().go(context);
            },
          ));
        }
      } catch (_) {
        // Silent fail — don't block the menu if the user count check fails
      }
    }

    ref.listen(posTerminalProvider, (prev, next) {
      checkAndShowPosDialog();
      unawaited(checkAndShowUsersDialog());
    });
    ref.listen(accessProvider, (prev, next) {
      checkAndShowPosDialog();
      unawaited(checkAndShowUsersDialog());
    });

    if (isAndroid) {
      return _AndroidMenuScreen(access: access);
    }

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          _MenuHeader(access: access),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: MenuGrid(role: access.role),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Android ─────────────────────────────────────────────────────────────────

class _AndroidMenuScreen extends StatelessWidget {
  const _AndroidMenuScreen({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    return AndroidScaffold(
      backgroundColor: ColorSet.background,
      body: SafeArea(
        child: Column(
          children: [
            _AndroidMenuHeader(access: access),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: MenuGrid(role: access.role),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AndroidMenuHeader extends StatelessWidget {
  const _AndroidMenuHeader({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final headerHeight = r.value<double>(kiosk: 72, tablet: 64, phone: 58);
    final logoHeight = r.value<double>(kiosk: 40, tablet: 32, phone: 26);
    final avatarSize = r.value<double>(kiosk: 44, tablet: 40, phone: 36);

    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(horizontal: r.value<double>(kiosk: 32, tablet: 24, phone: 16)),
      child: Row(
        children: [
          Assets.images.png.appBarLogo.image(height: logoHeight, fit: BoxFit.contain),
          const Spacer(),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(avatarSize),
            child: InkWell(
              borderRadius: BorderRadius.circular(avatarSize),
              onTap: () => _showAccountBottomSheet(context, access),
              child: _Avatar(name: access.fullName, size: avatarSize, fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountBottomSheet(BuildContext context, Access access) {
    showAndroidBottomSheet<void>(
      context: context,
      maxHeightRatio: 0.45,
      builder: (_) => _AccountBottomSheetContent(access: access),
    );
  }
}

class _AccountBottomSheetContent extends StatelessWidget {
  const _AccountBottomSheetContent({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final avatarSize = r.value<double>(kiosk: 72, tablet: 64, phone: 56);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 32, tablet: 24, phone: 20),
        vertical: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: POSColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
          _Avatar(name: access.fullName, size: avatarSize, fontSize: r.value<double>(kiosk: 28, tablet: 24, phone: 20)),
          const SizedBox(height: 12),
          Text(
            access.fullName,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ColorSet.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(POSRadius.full),
            ),
            child: Text(
              access.role.title,
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                color: ColorSet.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: r.value<double>(kiosk: 28, tablet: 24, phone: 20)),
          SizedBox(
            width: double.infinity,
            height: r.value<double>(kiosk: 60, tablet: 56, phone: 52),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                const OnboardingRoute().go(context);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('Sign Out', style: TextStyle(fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14))),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.danger,
                side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.6), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Windows menu header ───────────────────────────────────────────────────────

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.access});

  final Access access;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final headerHeight = r.value<double>(kiosk: 72, tablet: 64, phone: 58);
    final logoHeight = r.value<double>(kiosk: 40, tablet: 32, phone: 26);
    final avatarSize = r.value<double>(kiosk: 44, tablet: 38, phone: 32);
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEE, MMM d').format(now);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showDateTime = width >= 860;
        final iconOnly = width < 580;

        return Container(
          height: headerHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
            boxShadow: POSShadow.headerBottom,
          ),
          padding: EdgeInsets.symmetric(horizontal: r.hPagePadding),
          child: Row(
            children: [
              Assets.images.png.appBarLogo.image(height: logoHeight, fit: BoxFit.contain, color: ColorSet.secondary),
              if (showDateTime) ...[
                SizedBox(width: r.value<double>(kiosk: 24, tablet: 16, phone: 12)),
                Container(width: 1, height: 28, color: POSColors.borderDefault),
                SizedBox(width: r.value<double>(kiosk: 24, tablet: 16, phone: 12)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                        fontWeight: FontWeight.w700,
                        color: POSColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                        color: POSColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (iconOnly) ...[
                _Avatar(
                  name: access.fullName,
                  size: avatarSize,
                  fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                ),
                SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                IconButton(
                  onPressed: () => const OnboardingRoute().go(context),
                  icon: Icon(Icons.logout_rounded, size: r.value<double>(kiosk: 20, tablet: 18, phone: 16)),
                  color: ColorSet.danger,
                  tooltip: 'Sign Out',
                  style: IconButton.styleFrom(
                    backgroundColor: ColorSet.danger.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
                  ),
                ),
              ] else ...[
                Container(
                  height: r.value<double>(kiosk: 48, tablet: 42, phone: 36),
                  constraints: BoxConstraints(
                    maxWidth: r.value<double>(kiosk: 220, tablet: 200, phone: 180),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                    vertical: r.value<double>(kiosk: 8, tablet: 6, phone: 5),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                  ),
                  decoration: BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(POSRadius.full),
                    border: Border.all(color: POSColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Avatar(name: access.fullName, size: avatarSize * 0.8, fontSize: r.value<double>(kiosk: 13, tablet: 11, phone: 10)),
                      SizedBox(width: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              access.fullName,
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 14, tablet: 12, phone: 11),
                                fontWeight: FontWeight.w600,
                                color: POSColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              access.role.title,
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                                color: ColorSet.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                SizedBox(
                  height: r.value<double>(kiosk: 48, tablet: 42, phone: 36),
                  child: OutlinedButton.icon(
                    onPressed: () => const OnboardingRoute().go(context),
                    icon: Icon(Icons.logout_rounded, size: r.value<double>(kiosk: 16, tablet: 14, phone: 13)),
                    label: Text('Sign Out', style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 12, phone: 11))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSet.danger,
                      side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
                      padding: EdgeInsets.symmetric(horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size, required this.fontSize});

  final String name;
  final double size;
  final double fontSize;

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: POSGradient.primary,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
