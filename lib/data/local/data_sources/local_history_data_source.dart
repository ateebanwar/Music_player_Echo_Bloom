import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/mappers/history_mapper.dart';
import 'package:sound_foundry/data/mappers/track_mapper.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/history_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Concrete local data source for playback history in SQLite.
class LocalHistoryDataSource {
  final AppDatabase _appDatabase;
  final Uuid _uuid;

  LocalHistoryDataSource(this._appDatabase, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  Database get _db => _appDatabase.database;

  Future<void> recordPlay({
    required Track track,
    required Duration playedDuration,
    required bool completed,
    DateTime? playedAt,
  }) async {
    final timestamp = (playedAt ?? DateTime.now()).millisecondsSinceEpoch;
    final id = _uuid.v4();

    await _db.insert('playback_history', {
      'id': id,
      'track_id': track.id,
      'played_at': timestamp,
      'played_duration_ms': playedDuration.inMilliseconds,
      'completed': completed ? 1 : 0,
    });
  }

  Future<List<PlayHistoryItem>> getRecentHistory({int limit = 50}) async {
    final rows = await _db.rawQuery('''
      SELECT 
        h.id as history_id,
        h.played_at,
        h.played_duration_ms,
        h.completed,
        t.*
      FROM playback_history h
      INNER JOIN tracks t ON h.track_id = t.id
      ORDER BY h.played_at DESC
      LIMIT ?;
    ''', [limit]);

    return rows.map((r) => HistoryMapper.fromDbMap(r)).toList();
  }

  Future<List<Track>> getMostPlayedTracks({int limit = 20}) async {
    final rows = await _db.rawQuery('''
      SELECT 
        t.*,
        COUNT(h.id) as play_count
      FROM tracks t
      INNER JOIN playback_history h ON t.id = h.track_id
      GROUP BY t.id
      ORDER BY play_count DESC
      LIMIT ?;
    ''', [limit]);

    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<void> clearHistory() async {
    await _db.delete('playback_history');
  }
}
