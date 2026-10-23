import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/mappers/track_mapper.dart';
import 'package:sound_foundry/domain/entities/downloaded_playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite data source managing downloaded playlist collections and membership.
class DownloadedPlaylistDataSource {
  final AppDatabase _appDatabase;
  final AppLogger? _logger;

  DownloadedPlaylistDataSource({
    required AppDatabase appDatabase,
    AppLogger? logger,
  })  : _appDatabase = appDatabase,
        _logger = logger;

  DownloadPlaylistStatus _parseStatus(String str) {
    switch (str.toLowerCase()) {
      case 'queued':
        return DownloadPlaylistStatus.queued;
      case 'downloading':
        return DownloadPlaylistStatus.downloading;
      case 'partiallydownloaded':
      case 'partially_downloaded':
        return DownloadPlaylistStatus.partiallyDownloaded;
      case 'failed':
        return DownloadPlaylistStatus.failed;
      case 'downloaded':
      default:
        return DownloadPlaylistStatus.downloaded;
    }
  }

  String _statusToString(DownloadPlaylistStatus status) {
    switch (status) {
      case DownloadPlaylistStatus.queued:
        return 'queued';
      case DownloadPlaylistStatus.downloading:
        return 'downloading';
      case DownloadPlaylistStatus.partiallyDownloaded:
        return 'partially_downloaded';
      case DownloadPlaylistStatus.failed:
        return 'failed';
      case DownloadPlaylistStatus.downloaded:
        return 'downloaded';
    }
  }

  Future<List<DownloadedPlaylist>> getDownloadedPlaylists() async {
    final db = _appDatabase.database;
    final rows = await db.query('downloaded_playlists', orderBy: 'created_at DESC');

    final playlists = <DownloadedPlaylist>[];
    for (final row in rows) {
      final id = row['id'] as String;
      playlists.add(DownloadedPlaylist(
        id: id,
        name: row['name'] as String,
        description: row['description'] as String?,
        artworkUri: row['artwork_uri'] as String?,
        sourceType: (row['source_type'] as String?) ?? 'curated',
        remoteId: row['remote_id'] as String?,
        totalTracks: (row['total_tracks'] as num?)?.toInt() ?? 0,
        downloadedTracks: (row['downloaded_tracks'] as num?)?.toInt() ?? 0,
        status: _parseStatus((row['status'] as String?) ?? 'downloaded'),
        createdAt: DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
        updatedAt: DateTime.fromMillisecondsSinceEpoch((row['updated_at'] as num).toInt()),
      ));
    }
    return playlists;
  }

  Future<DownloadedPlaylist?> getDownloadedPlaylistById(String id) async {
    final db = _appDatabase.database;
    final rows = await db.query(
      'downloaded_playlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final row = rows.first;
    final tracks = await getDownloadedPlaylistTracks(id);

    return DownloadedPlaylist(
      id: id,
      name: row['name'] as String,
      description: row['description'] as String?,
      artworkUri: row['artwork_uri'] as String?,
      sourceType: (row['source_type'] as String?) ?? 'curated',
      remoteId: row['remote_id'] as String?,
      totalTracks: (row['total_tracks'] as num?)?.toInt() ?? 0,
      downloadedTracks: (row['downloaded_tracks'] as num?)?.toInt() ?? 0,
      status: _parseStatus((row['status'] as String?) ?? 'downloaded'),
      createdAt: DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((row['updated_at'] as num).toInt()),
      tracks: tracks,
    );
  }

  Future<List<Track>> getDownloadedPlaylistTracks(String playlistId) async {
    final db = _appDatabase.database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM tracks t
      INNER JOIN downloaded_playlist_items dpi ON dpi.track_id = t.id
      WHERE dpi.playlist_id = ?
      ORDER BY dpi.position ASC
    ''', [playlistId]);

    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<void> upsertDownloadedPlaylist(
    DownloadedPlaylist playlist,
    List<Track> tracks,
  ) async {
    final db = _appDatabase.database;
    await db.transaction((txn) async {
      await txn.insert(
        'downloaded_playlists',
        {
          'id': playlist.id,
          'name': playlist.name,
          'description': playlist.description,
          'artwork_uri': playlist.artworkUri,
          'source_type': playlist.sourceType,
          'remote_id': playlist.remoteId,
          'total_tracks': playlist.totalTracks,
          'downloaded_tracks': playlist.downloadedTracks,
          'status': _statusToString(playlist.status),
          'created_at': playlist.createdAt.millisecondsSinceEpoch,
          'updated_at': playlist.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        // Ensure track is inserted into tracks table if not already present
        final existing = await txn.query('tracks', columns: ['id'], where: 'id = ?', whereArgs: [track.id]);
        if (existing.isEmpty) {
          await txn.insert(
            'tracks',
            TrackMapper.toDbMap(track),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        await txn.insert(
          'downloaded_playlist_items',
          {
            'playlist_id': playlist.id,
            'track_id': track.id,
            'position': i,
            'download_status': 'completed',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _logger?.info('Upserted downloaded playlist ${playlist.name} with ${tracks.length} tracks', tag: 'DownloadedPlaylistDataSource');
  }

  Future<void> updatePlaylistProgress(
    String playlistId, {
    required int downloadedCount,
    required DownloadPlaylistStatus status,
  }) async {
    final db = _appDatabase.database;
    await db.update(
      'downloaded_playlists',
      {
        'downloaded_tracks': downloadedCount,
        'status': _statusToString(status),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> updateTrackItemStatus(
    String playlistId,
    String trackId,
    String status,
  ) async {
    final db = _appDatabase.database;
    await db.update(
      'downloaded_playlist_items',
      {'download_status': status},
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  Future<void> deleteDownloadedPlaylist(String playlistId) async {
    final db = _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        'downloaded_playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'downloaded_playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );
    });
    _logger?.info('Deleted downloaded playlist $playlistId', tag: 'DownloadedPlaylistDataSource');
  }

  /// Returns true if a track is still part of any other downloaded playlist collection.
  Future<bool> isTrackReferencedElsewhere(
    String trackId, {
    String? excludePlaylistId,
  }) async {
    final db = _appDatabase.database;
    final query = excludePlaylistId != null
        ? 'SELECT 1 FROM downloaded_playlist_items WHERE track_id = ? AND playlist_id != ? LIMIT 1'
        : 'SELECT 1 FROM downloaded_playlist_items WHERE track_id = ? LIMIT 1';
    final args = excludePlaylistId != null ? [trackId, excludePlaylistId] : [trackId];

    final rows = await db.rawQuery(query, args);
    return rows.isNotEmpty;
  }
}
