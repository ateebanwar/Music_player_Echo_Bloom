import 'dart:async';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/data/local/data_sources/local_track_data_source.dart';
import 'package:sound_foundry/data/remote/contracts/remote_music_data_source.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';

/// Concrete implementation of [TrackRepository].
/// Coordinates local SQLite data source and future remote data source.
class TrackRepositoryImpl implements TrackRepository {
  final LocalTrackDataSource _localDataSource;
  final RemoteMusicDataSource? _remoteDataSource;
  final AppLogger? _logger;
  final StreamController<int> _trackCountController = StreamController<int>.broadcast();

  TrackRepositoryImpl({
    required LocalTrackDataSource localDataSource,
    RemoteMusicDataSource? remoteDataSource,
    AppLogger? logger,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _logger = logger;

  @override
  Future<Result<PaginatedList<Track>, Failure>> getTracks(PageQuery query) async {
    try {
      final result = await _localDataSource.getTracks(query);
      return Result.ok(result);
    } catch (e, stack) {
      _logger?.error('Error fetching tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to query tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<Track, Failure>> getTrackById(String id) async {
    try {
      final track = await _localDataSource.getTrackById(id);
      if (track != null) {
        return Result.ok(track);
      }

      if (_remoteDataSource != null) {
        final remoteTrack = await _remoteDataSource.fetchTrackById(id);
        if (remoteTrack != null) {
          return Result.ok(remoteTrack);
        }
      }

      return Result.err(MediaNotFoundFailure(message: 'Track with ID $id was not found', pathOrUri: id));
    } catch (e, stack) {
      _logger?.error('Error fetching track by ID', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get track: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> searchTracks(String query) async {
    try {
      final tracks = await _localDataSource.searchTracks(query);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error searching tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to search tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> searchRemoteTracks(String query) async {
    if (_remoteDataSource == null) {
      return const Result.ok([]);
    }
    try {
      final tracks = await _remoteDataSource.searchRemoteCatalog(query);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error searching remote tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(NetworkFailure(message: 'Failed to search online music: $e', cause: e));
    }
  }

  @override
  Future<String> resolveStreamUri(String trackIdOrUri, [Track? track]) async {
    if (_remoteDataSource == null) {
      return trackIdOrUri;
    }
    try {
      final resolved = await _remoteDataSource.resolveStreamUri(trackIdOrUri, track);
      return resolved.isNotEmpty ? resolved : trackIdOrUri;
    } catch (e, stack) {
      _logger?.error('Error resolving stream URI', tag: 'TrackRepository', error: e, stackTrace: stack);
      return trackIdOrUri;
    }
  }

  @override
  Future<Result<List<Artist>, Failure>> getArtists() async {
    try {
      final artists = await _localDataSource.getArtists();
      return Result.ok(artists);
    } catch (e, stack) {
      _logger?.error('Error fetching artists', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get artists: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Album>, Failure>> getAlbums() async {
    try {
      final albums = await _localDataSource.getAlbums();
      return Result.ok(albums);
    } catch (e, stack) {
      _logger?.error('Error fetching albums', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get albums: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getTracksByArtist(String artistName) async {
    try {
      final tracks = await _localDataSource.getTracksByArtist(artistName);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching tracks by artist', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get artist tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getTracksByAlbum(String albumName) async {
    try {
      final tracks = await _localDataSource.getTracksByAlbum(albumName);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching tracks by album', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get album tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getFavoriteTracks() async {
    try {
      final tracks = await _localDataSource.getFavoriteTracks();
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching favorite tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get favorite tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getDownloadedTracks() async {
    try {
      final tracks = await _localDataSource.getDownloadedTracks();
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching downloaded tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get downloaded tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<bool, Failure>> toggleFavorite(String trackId, [Track? track]) async {
    try {
      final status = await _localDataSource.toggleFavorite(trackId, track);
      return Result.ok(status);
    } catch (e, stack) {
      _logger?.error('Error toggling favorite', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to toggle favorite: $e', cause: e));
    }
  }

  @override
  Future<Result<int, Failure>> upsertTracks(List<Track> tracks) async {
    try {
      final count = await _localDataSource.upsertTracks(tracks);
      _notifyTrackCountChanged();
      return Result.ok(count);
    } catch (e, stack) {
      _logger?.error('Error upserting tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to upsert tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<int, Failure>> deleteTracks(List<String> trackIds) async {
    try {
      final count = await _localDataSource.deleteTracks(trackIds);
      _notifyTrackCountChanged();
      return Result.ok(count);
    } catch (e, stack) {
      _logger?.error('Error deleting tracks', tag: 'TrackRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to delete tracks: $e', cause: e));
    }
  }

  @override
  Stream<int> watchTrackCount() {
    _notifyTrackCountChanged();
    return _trackCountController.stream;
  }

  void _notifyTrackCountChanged() async {
    try {
      final count = await _localDataSource.getTrackCount();
      if (!_trackCountController.isClosed) {
        _trackCountController.add(count);
      }
    } catch (_) {}
  }

  void dispose() {
    _trackCountController.close();
  }
}
