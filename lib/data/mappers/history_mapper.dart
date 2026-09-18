import 'package:sound_foundry/data/mappers/track_mapper.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/history_repository.dart';

/// Maps between SQLite Database rows and [PlayHistoryItem] domain entities.
abstract final class HistoryMapper {
  static PlayHistoryItem fromDbMap(Map<String, dynamic> map, [Track? track]) {
    final trackEntity = track ?? TrackMapper.fromDbMap(map);
    return PlayHistoryItem(
      id: map['history_id'] as String? ?? map['id'] as String,
      track: trackEntity,
      playedAt: DateTime.fromMillisecondsSinceEpoch(map['played_at'] as int),
      playedDuration: Duration(milliseconds: map['played_duration_ms'] as int),
      completed: (map['completed'] as int? ?? 0) == 1,
    );
  }

  static Map<String, dynamic> toDbMap(PlayHistoryItem item) {
    return <String, dynamic>{
      'id': item.id,
      'track_id': item.track.id,
      'played_at': item.playedAt.millisecondsSinceEpoch,
      'played_duration_ms': item.playedDuration.inMilliseconds,
      'completed': item.completed ? 1 : 0,
    };
  }
}
