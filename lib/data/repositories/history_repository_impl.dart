import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/data/local/data_sources/local_history_data_source.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/history_repository.dart';

/// Concrete implementation of [HistoryRepository].
class HistoryRepositoryImpl implements HistoryRepository {
  final LocalHistoryDataSource _localDataSource;
  final AppLogger? _logger;

  HistoryRepositoryImpl({
    required LocalHistoryDataSource localDataSource,
    AppLogger? logger,
  })  : _localDataSource = localDataSource,
        _logger = logger;

  @override
  Future<Result<void, Failure>> recordPlay({
    required Track track,
    required Duration playedDuration,
    required bool completed,
  }) async {
    try {
      await _localDataSource.recordPlay(
        track: track,
        playedDuration: playedDuration,
        completed: completed,
      );
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error recording play history', tag: 'HistoryRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to record play history: $e', cause: e));
    }
  }

  @override
  Future<Result<List<PlayHistoryItem>, Failure>> getRecentHistory({int limit = 50}) async {
    try {
      final history = await _localDataSource.getRecentHistory(limit: limit);
      return Result.ok(history);
    } catch (e, stack) {
      _logger?.error('Error fetching recent history', tag: 'HistoryRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get history: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getMostPlayedTracks({int limit = 20}) async {
    try {
      final tracks = await _localDataSource.getMostPlayedTracks(limit: limit);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching most played tracks', tag: 'HistoryRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get most played tracks: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> clearHistory() async {
    try {
      await _localDataSource.clearHistory();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error clearing history', tag: 'HistoryRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to clear history: $e', cause: e));
    }
  }
}
