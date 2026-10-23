import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/repositories/playlist_repository.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlists_screen.dart';

class FakePlaylistRepository implements PlaylistRepository {
  List<Playlist> playlists = [];
  Map<String, List<Track>> tracksByPlaylist = {};
  final List<String> deletedPlaylists = [];

  @override
  Future<Result<List<Playlist>, Failure>> getPlaylists() async {
    return Result.ok(playlists);
  }

  @override
  Future<Result<Playlist, Failure>> getPlaylistById(String id) async {
    final playlist = playlists.firstWhere((p) => p.id == id);
    return Result.ok(playlist);
  }

  @override
  Future<Result<List<Track>, Failure>> getPlaylistTracks(String playlistId) async {
    return Result.ok(tracksByPlaylist[playlistId] ?? []);
  }

  @override
  Future<Result<Playlist, Failure>> createPlaylist({
    required String name,
    String? description,
  }) async {
    final newPlaylist = Playlist(
      id: 'pl-${playlists.length + 1}',
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    playlists.add(newPlaylist);
    return Result.ok(newPlaylist);
  }

  @override
  Future<Result<Playlist, Failure>> updatePlaylist(Playlist playlist) async {
    final idx = playlists.indexWhere((p) => p.id == playlist.id);
    if (idx != -1) {
      playlists[idx] = playlist;
    }
    return Result.ok(playlist);
  }

  @override
  Future<Result<void, Failure>> deletePlaylist(String playlistId) async {
    deletedPlaylists.add(playlistId);
    playlists.removeWhere((p) => p.id == playlistId);
    tracksByPlaylist.remove(playlistId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    Track? track,
  }) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    tracksByPlaylist[playlistId]?.removeWhere((t) => t.id == trackId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> reorderTrack({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) async {
    return const Result.ok(null);
  }
}

class FakePlaybackRepository implements PlaybackRepository {
  List<Track>? lastQueue;
  int? lastInitialIndex;
  Track? lastPlayedTrack;

  @override
  Stream<PlaybackState> get playbackStateStream => const Stream.empty();

  @override
  PlaybackState get currentState => const PlaybackState(status: PlaybackStatus.idle);

  @override
  Future<Result<void, Failure>> setQueue(List<Track> queue, {int initialIndex = 0}) async {
    lastQueue = queue;
    lastInitialIndex = initialIndex;
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> playTrack(Track track) async {
    lastPlayedTrack = track;
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> addToQueue(Track track) async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> playNext(Track track) async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> play() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> pause() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> togglePlayPause() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> stop() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> seek(Duration position) async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> skipToNext() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> skipToPrevious() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> setRepeatMode(RepeatMode mode) async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> toggleShuffle() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> setVolume(double volume) async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> setSpeed(double speed) async => const Result.ok(null);
}

void main() {
  group('Playlist UX & Detail View Tests', () {
    late FakePlaylistRepository fakePlaylistRepo;
    late FakePlaybackRepository fakePlaybackRepo;

    final songA = Track(
      id: 'song-a',
      title: 'Song A',
      artist: 'Artist A',
      duration: const Duration(minutes: 3, seconds: 30),
      mediaUri: 'file:///music/song_a.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    final songB = Track(
      id: 'song-b',
      title: 'Song B',
      artist: 'Artist B',
      duration: const Duration(minutes: 4, seconds: 15),
      mediaUri: 'file:///music/song_b.mp3',
      dateAdded: DateTime(2026, 1, 2),
    );

    setUp(() {
      fakePlaylistRepo = FakePlaylistRepository();
      fakePlaybackRepo = FakePlaybackRepository();
    });

    testWidgets('Tapping playlist card in PlaylistsScreen opens PlaylistDetailScreen and DOES NOT play audio', (tester) async {
      final ateebPlaylist = Playlist(
        id: 'ateeb-1',
        name: 'Ateeb',
        trackCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [ateebPlaylist];
      fakePlaylistRepo.tracksByPlaylist['ateeb-1'] = [songA, songB];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlaylistsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Playlist card exists
      expect(find.text('Ateeb'), findsOneWidget);
      expect(find.text('2 Tracks'), findsOneWidget);

      // Tap on playlist card
      await tester.tap(find.text('Ateeb'));
      await tester.pumpAndSettle();

      // PlaylistDetailScreen should open
      expect(find.byType(PlaylistDetailScreen), findsOneWidget);

      // CRITICAL CHECK: Audio MUST NOT have started
      expect(fakePlaybackRepo.lastQueue, isNull);
      expect(fakePlaybackRepo.lastPlayedTrack, isNull);
      expect(fakePlaybackRepo.lastInitialIndex, isNull);

      // Verify songs inside playlist are displayed
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsOneWidget);
    });

    testWidgets('PlaylistDetailScreen shows accurate plural song count and individual songs', (tester) async {
      final ateebPlaylist = Playlist(
        id: 'ateeb-1',
        name: 'Ateeb',
        trackCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [ateebPlaylist];
      fakePlaylistRepo.tracksByPlaylist['ateeb-1'] = [songA, songB];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: PlaylistDetailScreen(
              playlistId: ateebPlaylist.id,
              initialPlaylist: ateebPlaylist,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Name & Plural count
      expect(find.text('Ateeb'), findsNWidgets(2)); // Header + banner
      expect(find.text('2 Songs'), findsOneWidget);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsOneWidget);
    });

    testWidgets('Tapping individual song in PlaylistDetailScreen starts playback with playlist queue', (tester) async {
      final ateebPlaylist = Playlist(
        id: 'ateeb-1',
        name: 'Ateeb',
        trackCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [ateebPlaylist];
      fakePlaylistRepo.tracksByPlaylist['ateeb-1'] = [songA, songB];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: PlaylistDetailScreen(
              playlistId: ateebPlaylist.id,
              initialPlaylist: ateebPlaylist,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Song A
      await tester.tap(find.text('Song A'));
      await tester.pump();

      expect(fakePlaybackRepo.lastQueue, isNotNull);
      expect(fakePlaybackRepo.lastQueue!.length, equals(2));
      expect(fakePlaybackRepo.lastInitialIndex, equals(0));

      // Tap Song B
      await tester.tap(find.text('Song B'));
      await tester.pump();

      expect(fakePlaybackRepo.lastInitialIndex, equals(1));
    });

    testWidgets('Empty playlist displays 0 Songs, clean empty state, and does not crash or autoplay', (tester) async {
      final emptyPlaylist = Playlist(
        id: 'empty-1',
        name: 'Empty Mix',
        trackCount: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [emptyPlaylist];
      fakePlaylistRepo.tracksByPlaylist['empty-1'] = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: PlaylistDetailScreen(
              playlistId: emptyPlaylist.id,
              initialPlaylist: emptyPlaylist,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 Songs'), findsOneWidget);
      expect(find.text('No songs in this playlist yet'), findsOneWidget);
      expect(find.text('Add songs from your library to get started'), findsOneWidget);
      expect(fakePlaybackRepo.lastQueue, isNull);
    });

    testWidgets('Single song playlist displays 1 Song (singular form)', (tester) async {
      final singlePlaylist = Playlist(
        id: 'single-1',
        name: 'Solo Track',
        trackCount: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [singlePlaylist];
      fakePlaylistRepo.tracksByPlaylist['single-1'] = [songA];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: PlaylistDetailScreen(
              playlistId: singlePlaylist.id,
              initialPlaylist: singlePlaylist,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 Song'), findsOneWidget);
      expect(find.text('Song A'), findsOneWidget);
    });

    testWidgets('Delete user playlist shows confirmation dialog, cancels on Cancel, deletes and pops on Delete', (tester) async {
      final userPlaylist = Playlist(
        id: 'user-p1',
        name: 'Ateeb',
        trackCount: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [userPlaylist];
      fakePlaylistRepo.tracksByPlaylist['user-p1'] = [songA];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlaylistDetailScreen(
                            playlistId: userPlaylist.id,
                            initialPlaylist: userPlaylist,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Ateeb'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Ateeb'));
      await tester.pumpAndSettle();

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);

      // Delete icon button is present
      final deleteBtn = find.byTooltip('Delete Playlist');
      expect(deleteBtn, findsOneWidget);

      // Tap Delete icon
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Delete Playlist?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete "Ateeb"?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fakePlaylistRepo.deletedPlaylists, isEmpty);
      expect(find.byType(PlaylistDetailScreen), findsOneWidget);

      // Tap Delete icon again
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      // Deletion should be requested
      expect(fakePlaylistRepo.deletedPlaylists, contains('user-p1'));

      // Detail screen should pop back
      expect(find.byType(PlaylistDetailScreen), findsNothing);
      expect(find.text('Open Ateeb'), findsOneWidget);
    });

    testWidgets('Protected playlist (Start Playlist or isSmartPlaylist) does not show delete action', (tester) async {
      final startPlaylist = Playlist(
        id: 'start-p1',
        name: 'Start Playlist',
        trackCount: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final smartPlaylist = Playlist(
        id: 'smart-p1',
        name: 'My Smart Playlist',
        isSmartPlaylist: true,
        trackCount: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      fakePlaylistRepo.playlists = [startPlaylist, smartPlaylist];

      // Test Start Playlist
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: PlaylistDetailScreen(
              playlistId: startPlaylist.id,
              initialPlaylist: startPlaylist,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byTooltip('Delete Playlist'), findsNothing);

      // Test isSmartPlaylist
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo),
            playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          ],
          child: MaterialApp(
            home: PlaylistDetailScreen(
              playlistId: smartPlaylist.id,
              initialPlaylist: smartPlaylist,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byTooltip('Delete Playlist'), findsNothing);
    });
  });
}
