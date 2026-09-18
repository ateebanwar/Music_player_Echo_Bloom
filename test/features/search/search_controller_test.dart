import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/features/search/search_controller.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  group('SearchController Tests — Mode Isolation & Online Integration', () {
    late MockTrackRepository mockRepo;
    late SearchController controller;

    final localTrack = Track(
      id: 'local_1',
      title: 'Local Song',
      artist: 'Local Artist',
      duration: const Duration(seconds: 200),
      mediaUri: '/storage/music/local.mp3',
      sourceType: TrackSourceType.localFile,
      dateAdded: DateTime.now(),
    );

    final remoteTrack = Track(
      id: 'jiosaavn_1',
      title: 'Remote Song',
      artist: 'Online Artist',
      duration: const Duration(seconds: 240),
      mediaUri: 'https://aac.saavncdn.com/online.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    setUp(() {
      mockRepo = MockTrackRepository();
    });

    test('In AppMode.offline: search queries ONLY local repository, ZERO remote calls', () async {
      when(() => mockRepo.searchTracks('Local')).thenAnswer((_) async => Result.ok([localTrack]));

      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('Local', immediate: true);

      expect(controller.state.localResults.length, 1);
      expect(controller.state.localResults.first.title, 'Local Song');
      expect(controller.state.remoteResults, isEmpty);

      // Verify ZERO remote queries were called
      verify(() => mockRepo.searchTracks('Local')).called(1);
      verifyNever(() => mockRepo.searchRemoteTracks(any()));
    });

    test('In AppMode.online: search queries remote tracks', () async {
      when(() => mockRepo.searchRemoteTracks('Online')).thenAnswer((_) async => Result.ok([remoteTrack]));

      controller = SearchController(mockRepo, AppMode.online);
      await controller.search('Online', immediate: true);

      expect(controller.state.remoteResults.length, 1);
      expect(controller.state.remoteResults.first.title, 'Remote Song');
      expect(controller.state.localResults, isEmpty);

      // Verify remote search was called
      verify(() => mockRepo.searchRemoteTracks('Online')).called(1);
      verifyNever(() => mockRepo.searchTracks(any()));
    });

    test('Empty query resets state to default without calling repositories', () async {
      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('   ', immediate: true);

      expect(controller.state.query, '');
      expect(controller.state.localResults, isEmpty);
      expect(controller.state.remoteResults, isEmpty);
      verifyNever(() => mockRepo.searchTracks(any()));
      verifyNever(() => mockRepo.searchRemoteTracks(any()));
    });

    test('Switching AppMode updates search results for active query', () async {
      when(() => mockRepo.searchTracks('Song')).thenAnswer((_) async => Result.ok([localTrack]));
      when(() => mockRepo.searchRemoteTracks('Song')).thenAnswer((_) async => Result.ok([remoteTrack]));

      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('Song', immediate: true);
      expect(controller.state.localResults.length, 1);

      // Switch to online mode
      controller.setAppMode(AppMode.online);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.remoteResults.length, 1);
      expect(controller.state.remoteResults.first.title, 'Remote Song');
      expect(controller.state.localResults, isEmpty);
    });
  });
}
