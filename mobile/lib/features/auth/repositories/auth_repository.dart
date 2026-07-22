import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Result<List<UserEntity>, AppError>> getActiveUsers();
  Future<Result<UserEntity, AppError>> login(int userId, String pin);
}
