import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/mappers/track_mapper.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sqflite/sqflite.dart';

/// Concrete local data source executing indexed SQLite queries for tracks.
class LocalTrackDataSource {
  final AppDatabase _appDatabase;

  const LocalTrackDataSource(this._appDatabase);

  Database get _db => _appDatabase.database;

  Future<PaginatedList<Track>> getTracks(PageQuery query) async {
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM tracks WHERE source_type != ?;',
      [TrackSourceType.remoteStream.index],
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    final sortCol = query.sortBy ?? 'title';
    final sortOrder = query.ascending ? 'ASC' : 'DESC';

    final rows = await _db.query(
      'tracks',
      where: 'source_type != ?',
      whereArgs: [TrackSourceType.remoteStream.index],
      orderBy: '$sortCol COLLATE NOCASE $sortOrder',
      limit: query.limit,
      offset: query.offset,
    );

    final items = rows.map(TrackMapper.fromDbMap).toList();
    return PaginatedList(
      items: items,
      totalCount: totalCount,
      offset: query.offset,
      limit: query.limit,
    );
  }

  Future<Track?> getTrackById(String id) async {
    final rows = await _db.query(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TrackMapper.fromDbMap(rows.first);
  }

  Future<List<Track>> searchTracks(String searchTerm) async {
    final pattern = '%$searchTerm%';
    final rows = await _db.query(
      'tracks',
      where: '(title LIKE ? OR artist LIKE ? OR album LIKE ?) AND source_type != ?',
      whereArgs: [pattern, pattern, pattern, TrackSourceType.remoteStream.index],
      orderBy: 'title COLLATE NOCASE ASC',
      limit: 100,
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Artist>> getArtists() async {
    final rows = await _db.rawQuery('''
      SELECT 
        artist as name,
        COUNT(*) as track_count,
        COUNT(DISTINCT album) as album_count,
        MIN(artwork_uri) as artwork_uri
      FROM tracks
      GROUP BY artist COLLATE NOCASE
      ORDER BY artist COLLATE NOCASE ASC;
    ''');

    return rows.map((r) => Artist(
      id: r['name'] as String,
      name: r['name'] as String,
      trackCount: r['track_count'] as int,
      albumCount: r['album_count'] as int,
      artworkUri: r['artwork_uri'] as String?,
    )).toList();
  }

  Future<List<Album>> getAlbums() async {
    final rows = await _db.rawQuery('''
      SELECT 
        COALESCE(album, 'Unknown Album') as title,
        artist,
        MIN(year) as year,
        COUNT(*) as track_count,
        MIN(artwork_uri) as artwork_uri
      FROM tracks
      WHERE album IS NOT NULL AND album != ''
      GROUP BY album COLLATE NOCASE, artist COLLATE NOCASE
      ORDER BY album COLLATE NOCASE ASC;
    ''');

    return rows.map((r) => Album(
      id: '${r['title']}_${r['artist']}',
      title: r['title'] as String,
      artist: r['artist'] as String,
      year: r['year'] as int?,
      trackCount: r['track_count'] as int,
      artworkUri: r['artwork_uri'] as String?,
    )).toList();
  }

  Future<List<Track>> getTracksByArtist(String artistName) async {
    final rows = await _db.query(
      'tracks',
      where: 'artist = ? COLLATE NOCASE',
      whereArgs: [artistName],
      orderBy: 'album COLLATE NOCASE ASC, track_number ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Track>> getTracksByAlbum(String albumName) async {
    final rows = await _db.query(
      'tracks',
      where: 'album = ? COLLATE NOCASE',
      whereArgs: [albumName],
      orderBy: 'disc_number ASC, track_number ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Track>> getFavoriteTracks() async {
    final rows = await _db.query(
      'tracks',
      where: 'is_favorite = 1',
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<bool> toggleFavorite(String trackId, [Track? track]) async {
    final existing = await getTrackById(trackId);
    if (existing == null && track != null) {
      await _db.insert(
        'tracks',
        TrackMapper.toDbMap(track.copyWith(isFavorite: true)),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }
    if (existing == null) return false;

    final newStatus = !existing.isFavorite;
    await _db.update(
      'tracks',
      {'is_favorite': newStatus ? 1 : 0},
      where: 'id = ?',
      whereArgs: [trackId],
    );
    return newStatus;
  }

  Future<int> upsertTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return 0;

    var count = 0;
    await _db.transaction((txn) async {
      // Query existing favorite track IDs to preserve user favorite state across rescans
      final existingFavoritesResult = await txn.query(
        'tracks',
        columns: ['id', 'media_uri'],
        where: 'is_favorite = 1',
      );
      final favoriteIds = <String>{};
      final favoriteUris = <String>{};
      for (final row in existingFavoritesResult) {
        if (row['id'] is String) favoriteIds.add(row['id'] as String);
        if (row['media_uri'] is String) favoriteUris.add(row['media_uri'] as String);
      }

      final batch = txn.batch();
      for (final track in tracks) {
        final isFav = favoriteIds.contains(track.id) ||
            favoriteUris.contains(track.mediaUri) ||
            track.isFavorite;

        final trackToSave = isFav != track.isFavorite
            ? track.copyWith(isFavorite: isFav)
            : track;

        final map = TrackMapper.toDbMap(trackToSave);
        final existing = await txn.query('tracks', columns: ['id'], where: 'id = ?', whereArgs: [trackToSave.id]);
        if (existing.isNotEmpty) {
          batch.update(
            'tracks',
            map,
            where: 'id = ?',
            whereArgs: [trackToSave.id],
          );
        } else {
          batch.insert(
            'tracks',
            map,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      final results = await batch.commit(noResult: false);
      count = results.length;
    });

    return count;
  }

  Future<int> deleteTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return 0;

    return await _db.delete(
      'tracks',
      where: 'id IN (${List.filled(trackIds.length, '?').join(',')})',
      whereArgs: trackIds,
    );
  }

  Future<int> getTrackCount() async {
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM tracks WHERE source_type != ?;',
      [TrackSourceType.remoteStream.index],
    );
    return Sqflite.firstIntValue(countResult) ?? 0;
  }

  Future<List<Track>> getDownloadedTracks() async {
    final rows = await _db.query(
      'tracks',
      where: 'source_type = ?',
      whereArgs: [TrackSourceType.downloaded.index],
      orderBy: 'date_added DESC',
    );

    final tracks = rows.map(TrackMapper.fromDbMap).toList();
    final validTracks = <Track>[];
    final staleIds = <String>[];

    for (final track in tracks) {
      if (kIsWeb || track.mediaUri.startsWith('blob:') || track.mediaUri.startsWith('offline://')) {
        validTracks.add(track);
      } else if (File(track.mediaUri).existsSync()) {
        validTracks.add(track);
      } else {
        staleIds.add(track.id);
      }
    }

    if (staleIds.isNotEmpty) {
      await deleteTracks(staleIds);
    }

    return validTracks;
  }
}
