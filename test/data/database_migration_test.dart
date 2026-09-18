import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/data/local/data_sources/local_playlist_data_source.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/local/database/database_migrator.dart';
import 'package:sound_foundry/data/local/database/migrations/v1_initial_schema.dart';
import 'package:sound_foundry/data/local/database/migrations/v2_online_tracks_schema.dart';
import 'package:sound_foundry/data/mappers/track_mapper.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Database Migrations and Schema', () {
    test('AppDatabase initializes schema v1 and v2 and creates tables with remote columns', () async {
      final appDb = AppDatabase(
        migrator: DatabaseMigrator(),
        databaseName: inMemoryDatabasePath,
      );

      final db = await appDb.initialize(
        inMemoryPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );

      expect(db.isOpen, isTrue);

      // Verify tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
      );
      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('tracks'));
      expect(tableNames, contains('playlists'));
      expect(tableNames, contains('playlist_items'));
      expect(tableNames, contains('playback_history'));
      expect(tableNames, contains('key_value_store'));

      // Verify v2 columns on tracks table
      final tableInfo = await db.rawQuery('PRAGMA table_info(tracks);');
      final columnNames = tableInfo.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('remote_provider'));
      expect(columnNames, contains('remote_provider_id'));
      expect(columnNames, contains('remote_perma_url'));

      await appDb.close();
      expect(appDb.isOpen, isFalse);
    });

    test('Migration v1 to v2 safely adds remote columns and preserves existing data', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await V1InitialSchema().up(db);
          },
        ),
      );

      // Insert track into v1 schema
      await db.insert('tracks', {
        'id': 'local-1',
        'title': 'Local Song',
        'artist': 'Local Artist',
        'duration_ms': 180000,
        'media_uri': '/storage/music/local.mp3',
        'source_type': 0,
        'date_added': 1000,
      });

      // Run v2 migration
      await V2OnlineTracksSchema().up(db);

      // Verify columns exist
      final tableInfo = await db.rawQuery('PRAGMA table_info(tracks);');
      final columnNames = tableInfo.map((c) => c['name'] as String).toList();
      expect(columnNames, contains('remote_provider'));
      expect(columnNames, contains('remote_provider_id'));
      expect(columnNames, contains('remote_perma_url'));

      // Verify existing track is intact and remote fields are null
      final rows = await db.query('tracks', where: 'id = ?', whereArgs: ['local-1']);
      expect(rows.length, equals(1));
      final track = TrackMapper.fromDbMap(rows.first);
      expect(track.id, equals('local-1'));
      expect(track.title, equals('Local Song'));
      expect(track.remoteProvider, isNull);
      expect(track.remoteProviderId, isNull);
      expect(track.remotePermaUrl, isNull);

      await db.close();
    });

    test('Online track persistence in playlists retains provider identity and prevents duplicates', () async {
      final appDb = AppDatabase(
        migrator: DatabaseMigrator(),
        databaseName: inMemoryDatabasePath,
      );

      await appDb.initialize(
        inMemoryPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );

      final playlistDataSource = LocalPlaylistDataSource(appDb);
      final playlist = await playlistDataSource.createPlaylist(name: 'Online Favorites');

      final onlineTrack = Track(
        id: 'jiosaavn_3qK45wE9',
        title: 'Kesariya',
        artist: 'Arijit Singh',
        album: 'Brahmastra',
        duration: const Duration(minutes: 4, seconds: 28),
        mediaUri: 'https://aac.saavncdn.com/stream/kesariya.mp4',
        sourceType: TrackSourceType.remoteStream,
        artworkUri: 'https://c.saavncdn.com/kesariya-500.jpg',
        dateAdded: DateTime.now(),
        remoteProvider: 'jiosaavn',
        remoteProviderId: '3qK45wE9',
        remotePermaUrl: 'https://www.jiosaavn.com/song/kesariya/3qK45wE9',
      );

      // Add track to playlist
      await playlistDataSource.addTrackToPlaylist(
        playlistId: playlist.id,
        trackId: onlineTrack.id,
        track: onlineTrack,
      );

      // Verify track is in playlist with all remote fields preserved
      final playlistTracks = await playlistDataSource.getPlaylistTracks(playlist.id);
      expect(playlistTracks.length, equals(1));
      final savedTrack = playlistTracks.first;
      expect(savedTrack.id, equals(onlineTrack.id));
      expect(savedTrack.title, equals('Kesariya'));
      expect(savedTrack.remoteProvider, equals('jiosaavn'));
      expect(savedTrack.remoteProviderId, equals('3qK45wE9'));
      expect(savedTrack.remotePermaUrl, equals('https://www.jiosaavn.com/song/kesariya/3qK45wE9'));

      // Try adding the same track again (duplicate check)
      await playlistDataSource.addTrackToPlaylist(
        playlistId: playlist.id,
        trackId: onlineTrack.id,
        track: onlineTrack,
      );

      // Verify no duplicates
      final updatedTracks = await playlistDataSource.getPlaylistTracks(playlist.id);
      expect(updatedTracks.length, equals(1));

      await appDb.close();
    });
  });
}
