import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../orders/state/orders_feed_notifier.dart';

/// Compact pill showing the live orders-feed WebSocket state. The status dot
/// pulses while the socket is not settled (connecting / reconnecting).
class ConnectionStatusIndicator extends ConsumerStatefulWidget {
  const ConnectionStatusIndicator({super.key, this.showLabel = true});

  /// When false only the status dot is rendered — used on narrow toolbars.
  final bool showLabel;

  @override
  ConsumerState<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState
    extends ConsumerState<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(ordersFeedNotifierProvider);
    final connection = feed.value?.connection ?? OrdersFeedConnection.connecting;
    final style = _StatusStyle.of(connection);

    if (style.animated) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1;
    }

    final dot = AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = style.animated
            ? 0.4 + (_pulse.value * 0.6)
            : 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: t),
            shape: BoxShape.circle,
          ),
        );
      },
    );

    return Semantics(
      label: 'Live feed: ${style.label}',
      container: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.showLabel ? 10 : 7,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot,
            if (widget.showLabel) ...[
              const SizedBox(width: 7),
              Text(
                style.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: style.color,
                  letterSpacing: 0,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.animated,
  });

  final String label;
  final Color color;
  final bool animated;

  static _StatusStyle of(OrdersFeedConnection connection) {
    switch (connection) {
      case OrdersFeedConnection.connected:
        return const _StatusStyle(
          label: 'Live',
          color: AppColors.success,
          animated: false,
        );
      case OrdersFeedConnection.connecting:
        return const _StatusStyle(
          label: 'Connecting',
          color: AppColors.warning,
          animated: true,
        );
      case OrdersFeedConnection.reconnecting:
        return const _StatusStyle(
          label: 'Reconnecting',
          color: AppColors.warning,
          animated: true,
        );
      case OrdersFeedConnection.disconnected:
        return const _StatusStyle(
          label: 'Offline',
          color: AppColors.textSecondary,
          animated: false,
        );
    }
  }
}
