import 'package:bcrypt/bcrypt.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../entities/user_entity.dart';
import 'auth_repository.dart';

UserEntity _toEntity(UsersTableData r) => UserEntity(
      id: r.id,
      name: r.name,
      role: r.role,
      isPinChanged: r.isPinChanged,
      employeeId: r.employeeId,
      phone: r.phone,
      avatarUrl: r.avatarUrl,
    );

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;

  const AuthRepositoryImpl(this._db);

  @override
  Future<Result<List<UserEntity>, AppError>> getActiveUsers() async {
    try {
      final rows = await _db.usersDao.getAllActiveUsers();
      return Success(rows.map(_toEntity).toList());
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

      return Success(_toEntity(row));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> verifyAdminPin(String pin) async {
    try {
      final rows = await _db.usersDao.getAllActiveUsers();
      final authorizers = rows.where((r) => r.role == 'admin' || r.role == 'supervisor');
      for (final authorizer in authorizers) {
        if (BCrypt.checkpw(pin, authorizer.pinHash)) return const Success(true);
      }
      return const Success(false);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<bool, AppError>> verifyPinForUser(int userId, String pin) async {
    try {
      final row = await _db.usersDao.getUserById(userId);
      if (row == null) return const Success(false);
      if (row.role != 'admin' && row.role != 'supervisor') return const Success(false);
      return Success(BCrypt.checkpw(pin, row.pinHash));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
