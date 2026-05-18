import 'package:dart_mappable/dart_mappable.dart';

import 'user_dto.dart';

part 'users_response_dto.mapper.dart';

@MappableClass()
class UsersResponseDto with UsersResponseDtoMappable {
  const UsersResponseDto({required this.data, this.total = 1, this.page = 1, this.limit = 10});

  final List<UserDto> data;
  final int total;
  final int page;
  final int limit;

  static const fromJson = UsersResponseDtoMapper.fromJson;
}
