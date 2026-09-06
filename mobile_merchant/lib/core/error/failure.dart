import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_exception.dart';

part 'failure.freezed.dart';

/// UI-facing error type. Repositories return `Either<Failure, T>`; notifiers
/// `.fold()` it into view state.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.network({required String message}) = NetworkFailure;

  const factory Failure.server({
    int? statusCode,
    required String message,
  }) = ServerFailure;

  const factory Failure.unauthorized() = UnauthorizedFailure;

  const factory Failure.forbidden() = ForbiddenFailure;

  const factory Failure.notFound() = NotFoundFailure;

  const factory Failure.validation({required String message}) = ValidationFailure;

  const factory Failure.unexpected({required String message}) = UnexpectedFailure;
}

extension FailureX on Failure {
  /// Human-readable string safe to show in the UI.
  String toMessage() => switch (this) {
        NetworkFailure(:final message) => message,
        ServerFailure(:final message) => message,
        UnauthorizedFailure() => 'Your session has expired. Please sign in again.',
        ForbiddenFailure() => 'You do not have permission to do that.',
        NotFoundFailure() => 'We could not find what you were looking for.',
        ValidationFailure(:final message) => message,
        UnexpectedFailure(:final message) => message,
      };

  /// Whether retrying the same request could plausibly succeed.
  bool get canRetry => switch (this) {
        NetworkFailure() => true,
        ServerFailure(:final statusCode) => (statusCode ?? 500) >= 500,
        _ => false,
      };

  /// Cross-boundary exception equivalent, thrown by datasource `Impl`s.
  AppException toException() => switch (this) {
        NetworkFailure(:final message) => NetworkException(message),
        ServerFailure(:final message, :final statusCode) =>
          ServerException(message, statusCode),
        UnauthorizedFailure() => const UnauthorizedException(),
        ForbiddenFailure() => const ForbiddenException(),
        NotFoundFailure() => const NotFoundException(),
        ValidationFailure(:final message) => ServerException(message, 422),
        UnexpectedFailure(:final message) => ServerException(message, null),
      };
}
