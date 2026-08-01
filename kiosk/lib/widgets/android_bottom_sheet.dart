import 'package:flutter/material.dart';

/// Standardised modal bottom sheet for Android following spec Section 2.
///
/// Applies [isScrollControlled], [useSafeArea], and a drag-handle pill at the
/// top. Callers supply the sheet content via [builder]; the drag handle and
/// rounding are added automatically.
///
/// [maxHeightRatio] controls the maximum fraction of the screen height the
/// sheet may occupy (default 0.92, matching the spec).
Future<T?> showAndroidBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightRatio = 0.92,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double borderRadius = 20,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * maxHeightRatio,
    ),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _DragHandle(),
        Flexible(child: builder(ctx)),
      ],
    ),
  );
}

/// 32×4 dp rounded pill, per spec: "drag handle bar (32×4px rounded pill)".
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
