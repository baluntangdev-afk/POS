import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';
import '../../../config/environment/orders_server_url.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../use_cases/check_orders_server_connection.dart';

const _kTotalSteps = 2;
const _kButtonHeight = 56.0;
const _kSwitchDuration = Duration(milliseconds: 220);

/// Login-screen server settings (only reachable when
/// `SKIP_DEVICE_REGISTRATION` is off): a password gate, then the orders
/// server address dialog. Shows a confirmation snackbar once the new address
/// is connected and saved.
Future<void> showOrdersServerSettings(BuildContext context) async {
  final unlocked = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _SettingsPasswordDialog(),
  );
  if (unlocked != true || !context.mounted) return;

  final connectedUrl = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OrdersServerDialog(),
  );
  if (connectedUrl == null || !context.mounted) return;

  final host = Uri.tryParse(connectedUrl)?.host ?? connectedUrl;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondaryLight),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected to orders server',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  Text(
                    host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.7),
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

// ─── Step 1: password gate ──────────────────────────────────────────────────

class _SettingsPasswordDialog extends HookConsumerWidget {
  const _SettingsPasswordDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expected = ref.read(appEnvProvider).settingsPassword;
    final notConfigured = expected.isEmpty;

    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final obscured = useState(true);
    final error = useState<String?>(null);
    final shake = useAnimationController(
      duration: const Duration(milliseconds: 420),
    );
    useListenable(controller);

    void submit() {
      if (controller.text.isEmpty || notConfigured) return;
      if (controller.text != expected) {
        error.value = 'Incorrect password. Try again.';
        HapticFeedback.mediumImpact();
        if (!MediaQuery.of(context).disableAnimations) {
          shake.forward(from: 0);
        }
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        focusNode.requestFocus();
        return;
      }
      Navigator.of(context).pop(true);
    }

    return _SettingsDialogShell(
      step: 1,
      icon: const _HeaderIcon(icon: Icons.lock_outline),
      title: 'Enter settings password',
      subtitle:
          'Server settings are protected. Ask your store admin for the '
          'password.',
      body:
          notConfigured
              ? const _Banner(
                tone: _BannerTone.warning,
                title: 'Settings are locked on this build',
                message:
                    'No settings password was set when this app was built. '
                    'Add SETTINGS_PASSWORD to .env and rebuild.',
              )
              : AnimatedBuilder(
                animation: shake,
                builder:
                    (context, child) => Transform.translate(
                      offset: Offset(
                        math.sin(shake.value * math.pi * 4) *
                            10 *
                            (1 - shake.value),
                        0,
                      ),
                      child: child,
                    ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  obscureText: obscured.value,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  style: AppTextStyles.bodyLg,
                  onSubmitted: (_) => submit(),
                  onChanged: (_) {
                    if (error.value != null) error.value = null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: error.value,
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      tooltip:
                          obscured.value ? 'Show password' : 'Hide password',
                      icon: Icon(
                        obscured.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => obscured.value = !obscured.value,
                    ),
                  ),
                ),
              ),
      secondary: _SecondaryButton(
        label: notConfigured ? 'Close' : 'Cancel',
        onPressed: () => Navigator.of(context).pop(false),
      ),
      primary:
          notConfigured
              ? null
              : _PrimaryButton(
                onPressed: controller.text.isEmpty ? null : submit,
                child: const _ButtonLabel(
                  key: ValueKey('continue'),
                  text: 'Continue',
                  trailing: Icon(Icons.arrow_forward, size: 18),
                ),
              ),
    );
  }
}

// ─── Step 2: orders server address ──────────────────────────────────────────

enum _ConnectPhase { idle, connecting, failed, connected }

class _OrdersServerDialog extends HookConsumerWidget {
  const _OrdersServerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.read(ordersServerUrlProvider),
    );
    final focusNode = useFocusNode();
    final phase = useState(_ConnectPhase.idle);
    final fieldError = useState<String?>(null);
    final connectError = useState<String?>(null);
    useListenable(controller);

    final locked =
        phase.value == _ConnectPhase.connecting ||
        phase.value == _ConnectPhase.connected;
    final defaultUrl = ref.read(appEnvProvider).ordersEventsApiBaseUrl;
    final hasText = controller.text.trim().isNotEmpty;

    void clearErrors() {
      fieldError.value = null;
      connectError.value = null;
      if (phase.value == _ConnectPhase.failed) phase.value = _ConnectPhase.idle;
    }

    Future<void> connect() async {
      final url = normalizeOrdersServerUrl(controller.text);
      if (url.isEmpty || locked) return;
      FocusScope.of(context).unfocus();
      fieldError.value = null;
      connectError.value = null;
      phase.value = _ConnectPhase.connecting;
      try {
        await checkOrdersServerConnection(url);
        await ref.read(ordersServerUrlProvider.notifier).save(url);
        if (!context.mounted) return;
        HapticFeedback.lightImpact();
        phase.value = _ConnectPhase.connected;
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (context.mounted) Navigator.of(context).pop(url);
      } on OrdersServerCheckException catch (e) {
        if (!context.mounted) return;
        HapticFeedback.mediumImpact();
        if (e.reason == OrdersServerCheckFailure.invalidAddress) {
          phase.value = _ConnectPhase.idle;
          fieldError.value = e.message;
          focusNode.requestFocus();
        } else {
          phase.value = _ConnectPhase.failed;
          connectError.value = e.message;
        }
      } catch (_) {
        if (!context.mounted) return;
        phase.value = _ConnectPhase.failed;
        connectError.value =
            'The address couldn\'t be saved on this device. '
            'Try again.';
      }
    }

    final host = Uri.tryParse(normalizeOrdersServerUrl(controller.text))?.host;

    final Widget buttonLabel = switch (phase.value) {
      _ConnectPhase.connecting => const _ButtonLabel(
        key: ValueKey('connecting'),
        text: 'Connecting…',
        leading: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
      _ConnectPhase.connected => const _ButtonLabel(
        key: ValueKey('connected'),
        text: 'Connected',
        leading: Icon(Icons.check, size: 20),
      ),
      _ConnectPhase.failed => const _ButtonLabel(
        key: ValueKey('retry'),
        text: 'Try again',
        leading: Icon(Icons.refresh, size: 20),
      ),
      _ConnectPhase.idle => const _ButtonLabel(
        key: ValueKey('connect'),
        text: 'Connect',
      ),
    };

    return PopScope(
      canPop: !locked,
      child: _SettingsDialogShell(
        step: 2,
        icon:
            phase.value == _ConnectPhase.connected
                ? const _HeaderIcon(
                  key: ValueKey('ok'),
                  icon: Icons.check_rounded,
                  success: true,
                )
                : const _HeaderIcon(
                  key: ValueKey('server'),
                  icon: Icons.dns_outlined,
                ),
        title: 'Orders server',
        subtitle: 'Where this device receives live orders.',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !locked,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.go,
              style: AppTextStyles.bodyLg,
              onSubmitted: (_) => connect(),
              onChanged: (_) => clearErrors(),
              decoration: InputDecoration(
                labelText: 'Server address',
                hintText: 'https://orders.example.com',
                helperText: 'Starts with http:// or https://',
                errorText: fieldError.value,
                errorMaxLines: 2,
                prefixIcon: const Icon(Icons.link),
                suffixIcon:
                    hasText && !locked
                        ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            controller.clear();
                            clearErrors();
                            focusNode.requestFocus();
                          },
                        )
                        : null,
              ),
            ),
            AnimatedSize(
              duration: _kSwitchDuration,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: switch (phase.value) {
                _ConnectPhase.connecting => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _StatusLine(
                    text:
                        'Contacting ${host == null || host.isEmpty ? 'server' : host}…',
                  ),
                ),
                _ConnectPhase.failed when connectError.value != null => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _Banner(
                    tone: _BannerTone.error,
                    title: 'Can\'t connect to this server',
                    message: connectError.value!,
                  ),
                ),
                _ConnectPhase.idle
                    when controller.text.trim() != defaultUrl &&
                        defaultUrl.isNotEmpty =>
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, AppSpacing.touchMin),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        textStyle: AppTextStyles.labelLg,
                      ),
                      onPressed: () {
                        controller.text = defaultUrl;
                        clearErrors();
                      },
                      icon: const Icon(Icons.settings_backup_restore, size: 18),
                      label: const Text('Use default address'),
                    ),
                  ),
                _ => const SizedBox(width: double.infinity),
              },
            ),
          ],
        ),
        secondary: _SecondaryButton(
          label: 'Cancel',
          onPressed: locked ? null : () => Navigator.of(context).pop(),
        ),
        primary: _PrimaryButton(
          success: phase.value == _ConnectPhase.connected,
          busy: phase.value == _ConnectPhase.connecting,
          onPressed: hasText && !locked ? connect : null,
          child: buttonLabel,
        ),
      ),
    );
  }
}

// ─── Shared pieces ──────────────────────────────────────────────────────────

class _SettingsDialogShell extends StatelessWidget {
  const _SettingsDialogShell({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.secondary,
    required this.primary,
  });

  final int step;
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget secondary;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: AppColors.shadow,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: _kSwitchDuration,
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: icon,
                  ),
                  const Spacer(),
                  _StepIndicator(step: step),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppTextStyles.headingLg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              body,
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: secondary),
                  if (primary != null) ...[
                    const SizedBox(width: AppSpacing.md - 4),
                    Expanded(flex: 3, child: primary!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $_kTotalSteps',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'STEP $step OF $_kTotalSteps',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= _kTotalSteps; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({super.key, required this.icon, this.success = false});

  final IconData icon;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color:
            success
                ? AppColors.successLight
                : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Icon(
        icon,
        size: 26,
        color: success ? AppColors.success : AppColors.primary,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.onPressed,
    required this.child,
    this.busy = false,
    this.success = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool busy;
  final bool success;

  @override
  Widget build(BuildContext context) {
    // Busy/success states disable the button but must keep their colour so
    // the spinner / "Connected" read as progress, not as a greyed-out button.
    final lockedColor =
        success
            ? AppColors.success
            : busy
            ? AppColors.primaryDark
            : null;
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(_kButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        disabledBackgroundColor: lockedColor,
        disabledForegroundColor:
            lockedColor == null ? null : AppColors.textOnPrimary,
      ),
      onPressed: onPressed,
      child: AnimatedSwitcher(duration: _kSwitchDuration, child: child),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(_kButtonHeight),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surfaceVariant,
        textStyle: AppTextStyles.labelLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    super.key,
    required this.text,
    this.leading,
    this.trailing,
  });

  final String text;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

enum _BannerTone { error, warning }

class _Banner extends StatelessWidget {
  const _Banner({
    required this.tone,
    required this.title,
    required this.message,
  });

  final _BannerTone tone;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (tone) {
      _BannerTone.error => (
        AppColors.errorLight,
        AppColors.error,
        Icons.error_outline,
      ),
      _BannerTone.warning => (
        AppColors.warningLight,
        AppColors.warning,
        Icons.info_outline,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLg.copyWith(color: fg)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textPrimary,
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
