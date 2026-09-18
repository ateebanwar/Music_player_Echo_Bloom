import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/data/local/data_sources/local_playlist_data_source.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/playlist_repository.dart';

/// Concrete implementation of [PlaylistRepository].
class PlaylistRepositoryImpl implements PlaylistRepository {
  final LocalPlaylistDataSource _localDataSource;
  final AppLogger? _logger;

  PlaylistRepositoryImpl({
    required LocalPlaylistDataSource localDataSource,
    AppLogger? logger,
  })  : _localDataSource = localDataSource,
        _logger = logger;

  @override
  Future<Result<List<Playlist>, Failure>> getPlaylists() async {
    try {
      final playlists = await _localDataSource.getPlaylists();
      return Result.ok(playlists);
    } catch (e, stack) {
      _logger?.error('Error fetching playlists', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get playlists: $e', cause: e));
    }
  }

  @override
  Future<Result<Playlist, Failure>> getPlaylistById(String id) async {
    try {
      final playlist = await _localDataSource.getPlaylistById(id);
      if (playlist == null) {
        return Result.err(MediaNotFoundFailure(message: 'Playlist with ID $id not found', pathOrUri: id));
      }
      return Result.ok(playlist);
    } catch (e, stack) {
      _logger?.error('Error fetching playlist by ID', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get playlist: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getPlaylistTracks(String playlistId) async {
    try {
      final tracks = await _localDataSource.getPlaylistTracks(playlistId);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching playlist tracks', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get playlist tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<Playlist, Failure>> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      final playlist = await _localDataSource.createPlaylist(
        name: name,
        description: description,
      );
      return Result.ok(playlist);
    } catch (e, stack) {
      _logger?.error('Error creating playlist', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to create playlist: $e', cause: e));
    }
  }

  @override
  Future<Result<Playlist, Failure>> updatePlaylist(Playlist playlist) async {
    try {
      await _localDataSource.updatePlaylist(playlist);
      return Result.ok(playlist);
    } catch (e, stack) {
      _logger?.error('Error updating playlist', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to update playlist: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> deletePlaylist(String playlistId) async {
    try {
      await _localDataSource.deletePlaylist(playlistId);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error deleting playlist', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to delete playlist: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    Track? track,
  }) async {
    try {
      await _localDataSource.addTrackToPlaylist(
        playlistId: playlistId,
        trackId: trackId,
        track: track,
      );
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error adding track to playlist', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to add track to playlist: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      await _localDataSource.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error removing track from playlist', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to remove track: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> reorderTrack({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) async {
    try {
      await _localDataSource.reorderTrack(
        playlistId: playlistId,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error reordering playlist track', tag: 'PlaylistRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to reorder track: $e', cause: e));
    }
  }
}
