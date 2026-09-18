import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sound_foundry/data/remote/clients/gaana_client.dart';
import 'package:sound_foundry/data/remote/clients/jiosaavn_client.dart';
import 'package:sound_foundry/data/remote/data_sources/remote_music_data_source_impl.dart';
import 'package:sound_foundry/domain/entities/track.dart';

class MockJioSaavnClient extends Mock implements JioSaavnClient {}
class MockGaanaClient extends Mock implements GaanaClient {}

void main() {
  group('RemoteMusicDataSourceImpl Tests', () {
    late MockJioSaavnClient mockJio;
    late MockGaanaClient mockGaana;
    late RemoteMusicDataSourceImpl dataSource;

    final dummyTrack = Track(
      id: 'jiosaavn_123',
      title: 'Kesariya',
      artist: 'Arijit Singh',
      duration: const Duration(seconds: 268),
      mediaUri: 'https://aac.saavncdn.com/sample.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    final dummyGaanaTrack = Track(
      id: 'gaana_kesariya',
      title: 'Kesariya (Gaana)',
      artist: 'Arijit Singh',
      duration: const Duration(seconds: 268),
      mediaUri: 'gaana://stream?seokey=kesariya',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    setUp(() {
      mockJio = MockJioSaavnClient();
      mockGaana = MockGaanaClient();
      dataSource = RemoteMusicDataSourceImpl(
        jioSaavnClient: mockJio,
        gaanaClient: mockGaana,
      );
    });

    test('Primary provider JioSaavn is used when results are returned', () async {
      when(() => mockJio.search('Kesariya')).thenAnswer((_) async => [dummyTrack]);

      final results = await dataSource.searchRemoteCatalog('Kesariya');

      expect(results.length, 1);
      expect(results.first.id, 'jiosaavn_123');
      verify(() => mockJio.search('Kesariya')).called(1);
      verifyNever(() => mockGaana.search(any()));
    });

    test('Fallback to Gaana activates when JioSaavn returns no results', () async {
      when(() => mockJio.search('Rare Song')).thenAnswer((_) async => []);
      when(() => mockGaana.search('Rare Song')).thenAnswer((_) async => [dummyGaanaTrack]);

      final results = await dataSource.searchRemoteCatalog('Rare Song');

      expect(results.length, 1);
      expect(results.first.id, 'gaana_kesariya');
      verify(() => mockJio.search('Rare Song')).called(1);
      verify(() => mockGaana.search('Rare Song')).called(1);
    });

    test('Fallback to Gaana activates when JioSaavn throws an exception', () async {
      when(() => mockJio.search('Error Song')).thenThrow(Exception('JioSaavn timeout'));
      when(() => mockGaana.search('Error Song')).thenAnswer((_) async => [dummyGaanaTrack]);

      final results = await dataSource.searchRemoteCatalog('Error Song');

      expect(results.length, 1);
      expect(results.first.id, 'gaana_kesariya');
      verify(() => mockJio.search('Error Song')).called(1);
      verify(() => mockGaana.search('Error Song')).called(1);
    });

    test('Caches search results to prevent duplicate network calls', () async {
      when(() => mockJio.search('Arijit')).thenAnswer((_) async => [dummyTrack]);

      final firstCall = await dataSource.searchRemoteCatalog('Arijit');
      final secondCall = await dataSource.searchRemoteCatalog('Arijit');

      expect(firstCall.length, 1);
      expect(secondCall.length, 1);
      verify(() => mockJio.search('Arijit')).called(1); // called only once!
    });

    test('resolveStreamUri returns direct HTTP URI as-is without network call', () async {
      const url = 'https://aac.saavncdn.com/test.mp4';
      final resolved = await dataSource.resolveStreamUri(url);
      expect(resolved, url);
      verifyNever(() => mockGaana.resolveStreamUri(any()));
    });

    test('resolveStreamUri resolves Gaana stream URL via GaanaClient', () async {
      when(() => mockGaana.resolveStreamUri('test-song'))
          .thenAnswer((_) async => 'https://stream.gaana.com/test.m3u8');

      final resolved = await dataSource.resolveStreamUri('gaana://stream?seokey=test-song');
      expect(resolved, 'https://stream.gaana.com/test.m3u8');
      verify(() => mockGaana.resolveStreamUri('test-song')).called(1);
    });
  });
}
