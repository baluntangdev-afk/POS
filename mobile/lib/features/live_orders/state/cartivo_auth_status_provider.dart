import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The latest Cartivo authentication failure message, or null when the last
/// attempt succeeded. Unlike a toast, it survives other SnackBars clearing the
/// messenger, so the Dashboard can keep showing it until auth recovers.
class CartivoAuthStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void reportFailure(String message) => state = message;

  void clear() => state = null;
}

final cartivoAuthStatusProvider =
    NotifierProvider<CartivoAuthStatusNotifier, String?>(
      CartivoAuthStatusNotifier.new,
    );
