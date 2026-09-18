import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Represents a listening history entry with play count and timestamp.
class PlayHistoryItem {
  final String id;
  final Track track;
  final DateTime playedAt;
  final Duration playedDuration;
  final bool completed;

  const PlayHistoryItem({
    required this.id,
    required this.track,
    required this.playedAt,
    required this.playedDuration,
    required this.completed,
  });
}

/// Contract for recording and querying playback history and statistics.
abstract class HistoryRepository {
  /// Records a track playback event.
  Future<Result<void, Failure>> recordPlay({
    required Track track,
    required Duration playedDuration,
    required bool completed,
  });

  /// Retrieves recent playback history.
  Future<Result<List<PlayHistoryItem>, Failure>> getRecentHistory({int limit = 50});

  /// Retrieves most frequently played tracks.
  Future<Result<List<Track>, Failure>> getMostPlayedTracks({int limit = 20});

  /// Clears listening history.
  Future<Result<void, Failure>> clearHistory();
}
