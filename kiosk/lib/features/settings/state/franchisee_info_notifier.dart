import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/franchisee_info.dart';
import '../repositories/franchisee_info_repository.dart';

final franchiseeInfoProvider = AsyncNotifierProvider.autoDispose(
  FranchiseeInfoNotifier.new,
  name: 'franchiseeInfoProvider',
);

class FranchiseeInfoNotifier extends AsyncNotifier<FranchiseeInfo> {
  @override
  Future<FranchiseeInfo> build() async {
    return ref.read(franchiseeInfoRepositoryProvider).fetch();
  }

  Future<void> updateFranchiseeInfo(FranchiseeInfo franchiseeInfo) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(franchiseeInfoRepositoryProvider).save(franchiseeInfo);
      return franchiseeInfo;
    });
  }
}
