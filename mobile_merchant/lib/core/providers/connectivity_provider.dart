import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/injection.dart';
import '../network/connectivity_service.dart';

part 'connectivity_provider.g.dart';

/// Streams `true` when the device is online, `false` when offline.
/// Drives the offline banner and retry gating.
@riverpod
Stream<bool> connectivityStatus(Ref ref) =>
    getIt<ConnectivityService>().onStatusChange;
