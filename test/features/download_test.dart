// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sound_foundry/data/local/data_sources/downloaded_playlist_data_source.dart';
import 'package:sound_foundry/data/local/data_sources/local_track_data_source.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/repositories/track_repository_impl.dart';
import 'package:sound_foundry/domain/entities/downloaded_playlist.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/download/download_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir.path;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Download Feature Tests', () {
    late Directory testTempDir;
    late AppDatabase appDb;
    late LocalTrackDataSource localDataSource;
    late TrackRepositoryImpl trackRepo;

    final sampleOnlineTrack = Track(
      id: 'jiosaavn_test123',
      title: 'Tum Hi Ho',
      artist: 'Arijit Singh',
      album: 'Aashiqui 2',
      duration: const Duration(minutes: 4, seconds: 22),
      mediaUri: 'https://aac.saavncdn.com/stream/test123.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime(2026, 1, 1),
      remoteProvider: 'jiosaavn',
      remoteProviderId: 'test123',
    );

    setUp(() async {
      testTempDir = await Directory.systemTemp.createTemp('sf_download_test_');
      PathProviderPlatform.instance = FakePathProviderPlatform(testTempDir);

      appDb = AppDatabase(databaseName: inMemoryDatabasePath);
      final db = await appDb.initialize(
        inMemoryPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      await db.delete('tracks');

      localDataSource = LocalTrackDataSource(appDb);
      trackRepo = TrackRepositoryImpl(localDataSource: localDataSource);
    });

    tearDown(() async {
      trackRepo.dispose();
      await appDb.close();
      if (testTempDir.existsSync()) {
        await testTempDir.delete(recursive: true);
      }
    });

    test('Downloads and persists online track locally with TrackSourceType.downloaded', () async {
      // Mock HTTP client providing audio data (>1KB to pass integrity test)
      final dummyAudioBytes = List<int>.filled(2048, 42);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(dummyAudioBytes, 200);
      });

      final controller = DownloadController(
        trackRepo,
        client: mockClient,
      );

      final success = await controller.downloadTrack(sampleOnlineTrack);
      expect(success, isTrue);

      final downloaded = controller.state.downloadedTracks;
      expect(downloaded.length, equals(1));

      final downloadedTrack = downloaded.first;
      expect(downloadedTrack.id, equals(sampleOnlineTrack.id));
      expect(downloadedTrack.sourceType, equals(TrackSourceType.downloaded));
      expect(downloadedTrack.fileSize, equals(2048));
      expect(File(downloadedTrack.mediaUri).existsSync(), isTrue);

      // Verify isTrackDownloaded check
      expect(controller.isTrackDownloaded(sampleOnlineTrack), isTrue);

      controller.dispose();
    });

    test('Duplicate download is prevented without creating redundant copies', () async {
      final dummyAudioBytes = List<int>.filled(2048, 42);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(dummyAudioBytes, 200);
      });

      final controller = DownloadController(
        trackRepo,
        client: mockClient,
      );

      // First download
      await controller.downloadTrack(sampleOnlineTrack);
      expect(controller.state.downloadedTracks.length, equals(1));

      // Second download attempt
      final repeatSuccess = await controller.downloadTrack(sampleOnlineTrack);
      expect(repeatSuccess, isTrue);
      expect(controller.state.downloadedTracks.length, equals(1));

      controller.dispose();
    });

    test('Deleting download removes local file and database entry', () async {
      final dummyAudioBytes = List<int>.filled(2048, 42);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(dummyAudioBytes, 200);
      });

      final controller = DownloadController(
        trackRepo,
        client: mockClient,
      );

      await controller.downloadTrack(sampleOnlineTrack);
      final savedTrack = controller.state.downloadedTracks.first;
      final filePath = savedTrack.mediaUri;
      expect(File(filePath).existsSync(), isTrue);

      await controller.deleteDownload(savedTrack);
      expect(controller.state.downloadedTracks.isEmpty, isTrue);
      expect(File(filePath).existsSync(), isFalse);

      controller.dispose();
    });

    test('Stale downloads pointing to deleted files are cleaned up gracefully', () async {
      final dummyAudioBytes = List<int>.filled(2048, 42);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(dummyAudioBytes, 200);
      });

      final controller = DownloadController(
        trackRepo,
        client: mockClient,
      );

      await controller.downloadTrack(sampleOnlineTrack);
      expect(controller.state.downloadedTracks.length, equals(1));

      // Manually delete the file externally
      final filePath = controller.state.downloadedTracks.first.mediaUri;
      await File(filePath).delete();
      expect(File(filePath).existsSync(), isFalse);

      // Reloading downloaded tracks should safely clean up stale database entry
      await controller.loadDownloadedTracks();
      expect(controller.state.downloadedTracks.isEmpty, isTrue);

      controller.dispose();
    });

    test('Downloading an entire playlist creates a playlist collection and tracks progress', () async {
      final downloadedPlaylistDs = DownloadedPlaylistDataSource(appDatabase: appDb);
      final dummyAudioBytes = List<int>.filled(2048, 42);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(dummyAudioBytes, 200);
      });

      final controller = DownloadController(
        trackRepo,
        client: mockClient,
        downloadedPlaylistDataSource: downloadedPlaylistDs,
      );

      final track2 = Track(
        id: 'jiosaavn_test456',
        title: 'Channa Mereya',
        artist: 'Arijit Singh',
        album: 'Ae Dil Hai Mushkil',
        duration: const Duration(minutes: 4, seconds: 49),
        mediaUri: 'https://aac.saavncdn.com/stream/test456.mp4',
        sourceType: TrackSourceType.remoteStream,
        dateAdded: DateTime(2026, 1, 1),
      );

      final playlist = Playlist(
        id: 'discovery_hindi_90s',
        name: '1990s Hindi Hits',
        trackCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = await controller.downloadPlaylist(playlist, [sampleOnlineTrack, track2]);
      expect(result, isTrue);

      final playlists = controller.state.downloadedPlaylists;
      expect(playlists.length, equals(1));
      expect(playlists.first.name, equals('1990s Hindi Hits'));
      expect(playlists.first.status, equals(DownloadPlaylistStatus.downloaded));
      expect(controller.state.playlistProgress[playlist.id], equals('2/2 downloaded'));

      // Verify offline tracks in playlist
      final tracksInPl = await downloadedPlaylistDs.getDownloadedPlaylistTracks(playlist.id);
      expect(tracksInPl.length, equals(2));

      controller.dispose();
    });

    test('Removing a downloaded playlist does not delete audio file if track is referenced elsewhere', () async {
      final downloadedPlaylistDs = DownloadedPlaylistDataSource(appDatabase: appDb);
      final dummyAudioBytes = List<int>.filled(2048, 42);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(dummyAudioBytes, 200);
      });

      final controller = DownloadController(
        trackRepo,
        client: mockClient,
        downloadedPlaylistDataSource: downloadedPlaylistDs,
      );

      final playlist1 = Playlist(
        id: 'pl_1',
        name: 'Playlist One',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final playlist2 = Playlist(
        id: 'pl_2',
        name: 'Playlist Two',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Download track into both playlists
      await controller.downloadPlaylist(playlist1, [sampleOnlineTrack]);
      await controller.downloadPlaylist(playlist2, [sampleOnlineTrack]);

      final downloadedTrack = controller.state.downloadedTracks.first;
      final localFilePath = downloadedTrack.mediaUri;
      expect(File(localFilePath).existsSync(), isTrue);

      // Delete playlist1 - file should remain because playlist2 still references it!
      await controller.deleteDownloadedPlaylist('pl_1');
      expect(File(localFilePath).existsSync(), isTrue);

      // Now delete playlist2 - file should now be deleted since no more references exist
      await controller.deleteDownloadedPlaylist('pl_2');
      expect(File(localFilePath).existsSync(), isFalse);

      controller.dispose();
    });
  });
}
