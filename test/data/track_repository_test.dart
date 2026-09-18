import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/data/local/data_sources/local_track_data_source.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/repositories/track_repository_impl.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('TrackRepositoryImpl integration', () {
    late AppDatabase appDatabase;
    late LocalTrackDataSource localDataSource;
    late TrackRepositoryImpl repository;

    final sampleTrack1 = Track(
      id: 'track-1',
      title: 'Stairway to Heaven',
      artist: 'Led Zeppelin',
      album: 'Led Zeppelin IV',
      duration: const Duration(minutes: 8, seconds: 2),
      mediaUri: '/music/stairway.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    final sampleTrack2 = Track(
      id: 'track-2',
      title: 'Kashmir',
      artist: 'Led Zeppelin',
      album: 'Physical Graffiti',
      duration: const Duration(minutes: 8, seconds: 37),
      mediaUri: '/music/kashmir.mp3',
      dateAdded: DateTime(2026, 1, 2),
    );

    setUp(() async {
      appDatabase = AppDatabase(databaseName: inMemoryDatabasePath);
      final db = await appDatabase.initialize(
        inMemoryPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      // Clear tracks table for clean isolated tests
      await db.delete('tracks');
      localDataSource = LocalTrackDataSource(appDatabase);
      repository = TrackRepositoryImpl(localDataSource: localDataSource);
    });

    tearDown(() async {
      repository.dispose();
      await appDatabase.close();
    });

    test('upserts, queries, and paginates tracks correctly', () async {
      final upsertRes = await repository.upsertTracks([sampleTrack1, sampleTrack2]);
      expect(upsertRes.isOk, isTrue);
      expect(upsertRes.valueOrNull, equals(2));

      final pageRes = await repository.getTracks(const PageQuery(offset: 0, limit: 10));
      expect(pageRes.isOk, isTrue);
      expect(pageRes.valueOrNull?.totalCount, equals(2));
      expect(pageRes.valueOrNull?.items.length, equals(2));

      final getByIdRes = await repository.getTrackById('track-1');
      expect(getByIdRes.isOk, isTrue);
      expect(getByIdRes.valueOrNull?.title, equals('Stairway to Heaven'));
    });

    test('searches and toggles favorite status correctly', () async {
      await repository.upsertTracks([sampleTrack1, sampleTrack2]);

      final searchRes = await repository.searchTracks('Kashmir');
      expect(searchRes.isOk, isTrue);
      expect(searchRes.valueOrNull?.length, equals(1));
      expect(searchRes.valueOrNull?.first.id, equals('track-2'));

      final favRes = await repository.toggleFavorite('track-1');
      expect(favRes.isOk, isTrue);
      expect(favRes.valueOrNull, isTrue);

      final favs = await repository.getFavoriteTracks();
      expect(favs.valueOrNull?.length, equals(1));
      expect(favs.valueOrNull?.first.id, equals('track-1'));
    });
  });
}
