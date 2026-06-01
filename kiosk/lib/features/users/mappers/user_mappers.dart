import '../../../data/backend_api/schemas/create_user_dto.dart';
import '../../../data/backend_api/schemas/user_dto.dart';
import '../entities/user.dart';

extension DTOMapper on UserDto {
  User get toEntity => User(
    id: id.toString(),
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    middleName: middleName,
    suffix: suffix == 'None' ? '' : suffix,
    email: email,
    phone: phone ?? '',
    image: image,
    systemAdmin: systemAdmin,
    role: role.isNotEmpty ? role : (systemAdmin ? 'admin' : 'user'),
    emailVerified: emailVerified,
    phoneVerified: phoneVerified,
    locked: locked,
    status: status,
    lastLogin: lastLogin,
    createdAt: createdAt,
    address: userDetails?.address ?? '',
    gender: userDetails?.gender ?? '',
    dateOfBirth: userDetails?.dateOfBirth,
    isPinChanged: isPinChanged,
  );
}

extension EntityMapper on User {
  UserDto get toModel => UserDto(
    id: int.tryParse(id) ?? 0,
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    middleName: middleName,
    suffix: suffix,
    email: email,
    phone: phone,
    image: image,
    systemAdmin: systemAdmin,
    emailVerified: emailVerified,
    phoneVerified: phoneVerified,
    locked: locked,
    status: status,
    lastLogin: lastLogin,
    createdAt: createdAt,
    isPinChanged: isPinChanged,
  );

  CreateUserDto get toRequest => CreateUserDto(
    id: id,
    email: email,
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    status: status,
    systemAdmin: role == 'admin',
    role: role,
    phone: phone,
    address: address,
    gender: gender,
    dateOfBirth: dateOfBirth != null ? dateOfBirth!.toIso8601String() : '',
    middleName: middleName ?? '',
    suffix: suffix.isEmpty ? 'None' : suffix,
  );
}
