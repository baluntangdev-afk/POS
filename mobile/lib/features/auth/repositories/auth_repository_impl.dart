import 'package:bcrypt/bcrypt.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../entities/user_entity.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;

  const AuthRepositoryImpl(this._db);

  @override
  Future<Result<List<UserEntity>, AppError>> getActiveUsers() async {
    try {
      final rows = await _db.usersDao.getAllActiveUsers();
      final users = rows.map((r) => UserEntity(id: r.id, name: r.name, role: r.role)).toList();
      return Success(users);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity, AppError>> login(int userId, String pin) async {
    try {
      final row = await _db.usersDao.getUserById(userId);
      if (row == null) return const Failure(NotFoundError('User not found'));

      final valid = BCrypt.checkpw(pin, row.pinHash);
      if (!valid) return const Failure(ValidationError('Incorrect PIN'));

      return Success(UserEntity(id: row.id, name: row.name, role: row.role));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> verifyAdminPin(String pin) async {
    try {
      final rows = await _db.usersDao.getAllActiveUsers();
      final admins = rows.where((r) => r.role == 'admin');
      for (final admin in admins) {
        if (BCrypt.checkpw(pin, admin.pinHash)) return const Success(true);
      }
      return const Success(false);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
