import 'package:equatable/equatable.dart';
import 'package:sound_foundry/core/errors/failures.dart';

/// Sealed Result type representing either a [Success] value of type [T]
/// or a [Failure] value of type [F] (which defaults to [Failure]).
sealed class Result<T, F extends Failure> extends Equatable {
  const Result();

  /// Creates a successful result containing [value].
  const factory Result.ok(T value) = Ok<T, F>;

  /// Creates a failed result containing [failure].
  const factory Result.err(F failure) = Err<T, F>;

  /// Returns true if this is an [Ok] instance.
  bool get isOk => this is Ok<T, F>;

  /// Returns true if this is an [Err] instance.
  bool get isErr => this is Err<T, F>;

  /// Returns the wrapped value if [Ok], or null if [Err].
  T? get valueOrNull => switch (this) {
        Ok(value: final v) => v,
        Err() => null,
      };

  /// Returns the wrapped failure if [Err], or null if [Ok].
  F? get failureOrNull => switch (this) {
        Ok() => null,
        Err(failure: final f) => f,
      };

  /// Pattern-matches over both branches.
  R when<R>({
    required R Function(T value) ok,
    required R Function(F failure) err,
  }) {
    return switch (this) {
      Ok(value: final v) => ok(v),
      Err(failure: final f) => err(f),
    };
  }

  /// Maps the success value using [fn] if [Ok], otherwise forwards [Err].
  Result<R, F> map<R>(R Function(T value) fn) {
    return switch (this) {
      Ok(value: final v) => Result.ok(fn(v)),
      Err(failure: final f) => Result.err(f),
    };
  }

  /// Maps the failure using [fn] if [Err], otherwise forwards [Ok].
  Result<T, R> mapError<R extends Failure>(R Function(F failure) fn) {
    return switch (this) {
      Ok(value: final v) => Result.ok(v),
      Err(failure: final f) => Result.err(fn(f)),
    };
  }

  /// Chains asynchronous operations returning a [Result].
  Future<Result<R, F>> flatMap<R>(
      Future<Result<R, F>> Function(T value) fn) async {
    return switch (this) {
      Ok(value: final v) => await fn(v),
      Err(failure: final f) => Result.err(f),
    };
  }
}

/// Represents a successful computation.
final class Ok<T, F extends Failure> extends Result<T, F> {
  final T value;

  const Ok(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Result.ok($value)';
}

/// Represents a failed computation.
final class Err<T, F extends Failure> extends Result<T, F> {
  final F failure;

  const Err(this.failure);

  @override
  List<Object?> get props => [failure];

  @override
  String toString() => 'Result.err($failure)';
}
