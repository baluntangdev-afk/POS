import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_notifier.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
