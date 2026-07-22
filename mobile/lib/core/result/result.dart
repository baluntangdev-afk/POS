sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T get value => (this as Success<T, E>).value;
  E get error => (this as Failure<T, E>).error;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure(:final error) => onFailure(error),
      };
}

final class Success<T, E> extends Result<T, E> {
  @override
  final T value;
  const Success(this.value);
}

final class Failure<T, E> extends Result<T, E> {
  @override
  final E error;
  const Failure(this.error);
}
