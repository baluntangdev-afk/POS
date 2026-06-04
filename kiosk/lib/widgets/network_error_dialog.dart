import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../styles/color_set.dart';
import '../styles/responsive/breakpoint.dart';
import '../styles/responsive/responsive_value.dart';

typedef _ErrorInfo = ({IconData icon, String title, String message});

Future<void> showNetworkErrorDialog(
  BuildContext context, {
  required Object error,
  VoidCallback? onRetry,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Error',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) =>
        NetworkErrorDialog(error: error, onRetry: onRetry),
    transitionBuilder: (context, animation, _, child) {
      final scale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

class NetworkErrorDialog extends StatefulWidget {
  const NetworkErrorDialog({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  State<NetworkErrorDialog> createState() => _NetworkErrorDialogState();
}

class _NetworkErrorDialogState extends State<NetworkErrorDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _shakeController.forward();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;
    final info = _resolveErrorInfo(widget.error);

    double width, padding, iconSize, titleSize, messageSize;
    if (breakpoint.isPhone) {
      width = 320;
      padding = 20;
      iconSize = 40;
      titleSize = 25;
      messageSize = 18;
    } else if (breakpoint.isTablet) {
      width = 360;
      padding = 22;
      iconSize = 50;
      titleSize = 28;
      messageSize = 20;
    } else {
      width = 380;
      padding = 24;
      iconSize = 60;
      titleSize = 30;
      messageSize = 22;
    }

    final containerSize = iconSize * 1.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ColorSet.light,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorSet.danger.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: containerSize * 0.4,
                bottom: containerSize * 0.25,
              ),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder:
                    (context, child) => Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    ),
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: ColorSet.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(info.icon, color: ColorSet.danger, size: iconSize),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
              child: Column(
                children: [
                  Text(
                    info.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: ColorSet.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: titleSize * 0.5),
                  Text(
                    info.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: messageSize,
                      fontWeight: FontWeight.w400,
                      color: ColorSet.text.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: padding),
                  _buildButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final buttonFontSize = context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 22);

    if (widget.onRetry != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  color: ColorSet.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: buttonFontSize,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRetry!();
              },
              style: FilledButton.styleFrom(
                backgroundColor: ColorSet.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: ColorSet.light,
                  fontWeight: FontWeight.w600,
                  fontSize: buttonFontSize,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: ColorSet.danger,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'OK',
          style: TextStyle(
            color: ColorSet.light,
            fontWeight: FontWeight.w600,
            fontSize: buttonFontSize,
          ),
        ),
      ),
    );
  }
}

_ErrorInfo _resolveErrorInfo(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError) {
      return (
        icon: Icons.wifi_off_rounded,
        title: 'No Connection',
        message:
            'Unable to reach the server. Please wait a moment and try again.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return (
        icon: Icons.timer_off_rounded,
        title: 'Request Timed Out',
        message: 'The connection took too long to respond. Please try again.',
      );
    }
    return _infoFromHttpError(error);
  }

  final msg =
      error is AppException && error.message.isNotEmpty
          ? error.message
          : error.toString().replaceAll('Exception: ', '');
  return (
    icon: Icons.error_rounded,
    title: 'Error',
    message: msg.isNotEmpty ? msg : 'An unexpected error occurred.',
  );
}

_ErrorInfo _infoFromHttpError(DioException error) {
  final status = error.response?.statusCode;
  final data = error.response?.data;
  final serverMsg =
      data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

  if (status != null && status >= 500) {
    return (
      icon: Icons.cloud_off_rounded,
      title: 'Server Error',
      message: serverMsg ?? 'The server is currently unavailable. Please try again later.',
    );
  }
  return (
    icon: Icons.error_rounded,
    title: 'Request Failed',
    message: serverMsg ?? 'The request could not be completed. Please try again.',
  );
}
