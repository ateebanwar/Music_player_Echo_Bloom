import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/mappers/playlist_mapper.dart';
import 'package:sound_foundry/data/mappers/track_mapper.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Concrete local data source for managing playlists and playlist tracks in SQLite.
class LocalPlaylistDataSource {
  final AppDatabase _appDatabase;
  final Uuid _uuid;

  LocalPlaylistDataSource(this._appDatabase, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  Database get _db => _appDatabase.database;

  Future<List<Playlist>> getPlaylists() async {
    final rows = await _db.rawQuery('''
      SELECT 
        p.*,
        COUNT(pi.track_id) as track_count,
        COALESCE(SUM(t.duration_ms), 0) as total_duration_ms
      FROM playlists p
      LEFT JOIN playlist_items pi ON p.id = pi.playlist_id
      LEFT JOIN tracks t ON pi.track_id = t.id
      GROUP BY p.id
      ORDER BY p.name COLLATE NOCASE ASC;
    ''');

    return rows.map(PlaylistMapper.fromDbMap).toList();
  }

  Future<Playlist?> getPlaylistById(String id) async {
    final rows = await _db.rawQuery('''
      SELECT 
        p.*,
        COUNT(pi.track_id) as track_count,
        COALESCE(SUM(t.duration_ms), 0) as total_duration_ms
      FROM playlists p
      LEFT JOIN playlist_items pi ON p.id = pi.playlist_id
      LEFT JOIN tracks t ON pi.track_id = t.id
      WHERE p.id = ?
      GROUP BY p.id
      LIMIT 1;
    ''', [id]);

    if (rows.isEmpty) return null;
    return PlaylistMapper.fromDbMap(rows.first);
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final rows = await _db.rawQuery('''
      SELECT t.*
      FROM tracks t
      INNER JOIN playlist_items pi ON t.id = pi.track_id
      WHERE pi.playlist_id = ?
      ORDER BY pi.position ASC;
    ''', [playlistId]);

    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final id = _uuid.v4();
    final playlist = Playlist(
      id: id,
      name: name,
      description: description,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await _db.insert('playlists', PlaylistMapper.toDbMap(playlist));
    return playlist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _db.update(
      'playlists',
      PlaylistMapper.toDbMap(playlist),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    Track? track,
    DateTime? now,
  }) async {
    // Check if track is already in the playlist to prevent duplicates
    final existingItem = await _db.query(
      'playlist_items',
      columns: ['track_id'],
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
      limit: 1,
    );
    if (existingItem.isNotEmpty) {
      return;
    }

    // If track is provided, ensure it is safely persisted in the tracks table first
    if (track != null) {
      // Ensure mediaUri is never empty to prevent SQLite UNIQUE/NOT NULL constraint violation
      final safeTrack = track.mediaUri.isEmpty
          ? track.copyWith(
              mediaUri: track.remotePermaUrl ?? 'remote://${track.id}',
            )
          : track;

      await _db.insert(
        'tracks',
        TrackMapper.toDbMap(safeTrack),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final posResult = await _db.rawQuery('''
      SELECT COALESCE(MAX(position), -1) + 1 as next_pos
      FROM playlist_items
      WHERE playlist_id = ?;
    ''', [playlistId]);

    final nextPos = (posResult.first['next_pos'] as int?) ?? 0;
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;

    await _db.insert(
      'playlist_items',
      {
        'playlist_id': playlistId,
        'track_id': trackId,
        'position': nextPos,
        'added_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await _touchPlaylist(playlistId, now);
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    await _db.delete(
      'playlist_items',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
    await _touchPlaylist(playlistId);
  }

  Future<void> reorderTrack({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final items = await _db.query(
      'playlist_items',
      where: 'playlist_id = ?',
      orderBy: 'position ASC',
    );

    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex >= items.length) {
      return;
    }

    final mutableItems = List<Map<String, dynamic>>.from(items);
    final moved = mutableItems.removeAt(oldIndex);
    mutableItems.insert(newIndex, moved);

    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < mutableItems.length; i++) {
        batch.update(
          'playlist_items',
          {'position': i},
          where: 'playlist_id = ? AND track_id = ?',
          whereArgs: [playlistId, mutableItems[i]['track_id']],
        );
      }
      await batch.commit(noResult: true);
    });

    await _touchPlaylist(playlistId);
  }

  Future<void> _touchPlaylist(String playlistId, [DateTime? now]) async {
    await _db.update(
      'playlists',
      {'updated_at': (now ?? DateTime.now()).millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }
}
