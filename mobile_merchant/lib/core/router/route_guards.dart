import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Redirect logic for the router.
///
/// STUB: the app currently has no auth feature, so [redirect] always returns
/// `null` (no redirect) and [RouterNotifier] never refreshes. When the `auth`
/// feature lands:
///   1. inject `authNotifierProvider` and listen to it in the constructor,
///   2. implement the logged-in / on-login checks in [redirect],
///   3. pass this notifier as `refreshListenable` in `app_router.dart`.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref);

  // ignore: unused_field
  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) => null;
}
