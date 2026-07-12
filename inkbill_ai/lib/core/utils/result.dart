import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

sealed class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  });

  T get dataOrThrow {
    final result = this;
    if (result is Success<T>) return result.data;
    throw (result as Error<T>).failure;
  }

  Failure? get errorOrNull {
    final result = this;
    if (result is Error<T>) return result.failure;
    return null;
  }

  T? get dataOrNull {
    final result = this;
    if (result is Success<T>) return result.data;
    return null;
  }

  factory Result.success(T data) = Success<T>;
  factory Result.error(Failure failure) = Error<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) =>
      success(data);

  @override
  List<Object?> get props => [data];
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) =>
      error(failure);

  @override
  List<Object?> get props => [failure];
}
