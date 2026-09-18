import 'package:equatable/equatable.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';

/// Base interface for asynchronous one-shot use cases.
abstract class UseCase<T, Params> {
  Future<Result<T, Failure>> call(Params params);
}

/// Base interface for streaming use cases.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Placeholder for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
