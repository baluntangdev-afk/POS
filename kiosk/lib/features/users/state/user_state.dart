import 'package:dart_mappable/dart_mappable.dart';

import '../entities/user.dart';

part 'user_state.mapper.dart';

@MappableClass()
sealed class UserState with UserStateMappable {
  const UserState();
}

@MappableClass()
class UserStateInitial extends UserState with UserStateInitialMappable {
  const UserStateInitial();
}

@MappableClass()
class UserSuccessCreate extends UserState with UserSuccessCreateMappable {
  const UserSuccessCreate(this.user);

  final User user;
}

@MappableClass()
class UserSuccessEdit extends UserState with UserSuccessEditMappable {
  const UserSuccessEdit(this.user);

  final User user;
}

@MappableClass()
class UserSuccessGet extends UserState with UserSuccessGetMappable {
  const UserSuccessGet(this.user);

  final User user;
}

@MappableClass()
class UserSuccessDelete extends UserState with UserSuccessDeleteMappable {
  const UserSuccessDelete(this.userId);

  final String userId;
}

@MappableClass()
class UserSuccessReset extends UserState with UserSuccessResetMappable {
  const UserSuccessReset(this.userId);

  final String userId;
}
