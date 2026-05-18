import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';

class Debounce {
  Debounce(this.delay, {this.onCancel});

  final Duration delay;

  final void Function()? onCancel;

  Timer? _timer;

  void call(void Function() fn) {
    if (_timer?.isActive ?? false) cancel();
    _timer = Timer(delay, fn);
  }

  void cancel() {
    onCancel?.call();
    _timer?.cancel();
  }
}

Debounce useDebounce(Duration delay, {void Function()? onCancel}) {
  final debounce = useMemoized(() => Debounce(delay, onCancel: onCancel), [delay, onCancel]);

  useEffect(() {
    return debounce.cancel;
  }, [debounce]);

  return debounce;
}
