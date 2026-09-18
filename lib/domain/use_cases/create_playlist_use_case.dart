import 'package:equatable/equatable.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/repositories/playlist_repository.dart';
import 'package:sound_foundry/domain/use_cases/use_case.dart';

class CreatePlaylistParams extends Equatable {
  final String name;
  final String? description;

  const CreatePlaylistParams({
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [name, description];
}

/// Creates a new user playlist with validation.
class CreatePlaylistUseCase implements UseCase<Playlist, CreatePlaylistParams> {
  final PlaylistRepository _repository;

  const CreatePlaylistUseCase(this._repository);

  @override
  Future<Result<Playlist, Failure>> call(CreatePlaylistParams params) {
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) {
      return Future.value(
        const Result.err(ValidationFailure(message: 'Playlist name cannot be empty')),
      );
    }
    return _repository.createPlaylist(
      name: trimmedName,
      description: params.description?.trim(),
    );
  }
}
