import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/config/app_config.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/logging/console_logger.dart';
import 'package:sound_foundry/core/time/clock.dart';
import 'package:sound_foundry/data/local/data_sources/local_history_data_source.dart';
import 'package:sound_foundry/data/local/data_sources/local_playlist_data_source.dart';
import 'package:sound_foundry/data/local/data_sources/local_track_data_source.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/data/remote/contracts/remote_music_data_source.dart';
import 'package:sound_foundry/data/remote/data_sources/remote_music_data_source_impl.dart';
import 'package:sound_foundry/data/repositories/equalizer_repository_impl.dart';
import 'package:sound_foundry/data/repositories/history_repository_impl.dart';
import 'package:sound_foundry/data/repositories/playlist_repository_impl.dart';
import 'package:sound_foundry/data/repositories/settings_repository_impl.dart';
import 'package:sound_foundry/data/repositories/track_repository_impl.dart';
import 'package:sound_foundry/data/repositories/user_profile_repository_impl.dart';
import 'package:sound_foundry/domain/repositories/equalizer_repository.dart';
import 'package:sound_foundry/domain/repositories/history_repository.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/repositories/playlist_repository.dart';
import 'package:sound_foundry/domain/repositories/settings_repository.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/domain/repositories/user_profile_repository.dart';
import 'package:sound_foundry/features/playback/playback_repository_impl.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine_impl.dart';
import 'package:sound_foundry/infrastructure/audio/audio_focus_manager.dart';
import 'package:sound_foundry/infrastructure/permissions/permission_service.dart';
import 'package:sound_foundry/infrastructure/platform/media_scanner.dart';
import 'package:sound_foundry/infrastructure/storage/key_value_store.dart';

// --- Core Providers ---

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.development();
});

final loggerProvider = Provider<AppLogger>((ref) {
  final config = ref.watch(appConfigProvider);
  return ConsoleLogger(
    enableInRelease: config.buildConfig.enableVerboseLogging,
  );
});

final clockProvider = Provider<Clock>((ref) {
  return const SystemClock();
});

// --- Infrastructure Providers ---

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final logger = ref.watch(loggerProvider);
  return AppDatabase(logger: logger);
});

final keyValueStoreProvider = Provider<KeyValueStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SqliteKeyValueStore(db);
});

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final logger = ref.watch(loggerProvider);
  final engine = AudioEngineImpl(logger: logger);
  ref.onDispose(engine.dispose);
  return engine;
});

final audioFocusManagerProvider = Provider<AudioFocusManager>((ref) {
  return DefaultAudioFocusManager();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return DefaultPermissionService();
});

final mediaScannerProvider = Provider<MediaScanner>((ref) {
  final permService = ref.watch(permissionServiceProvider);
  final logger = ref.watch(loggerProvider);
  return DefaultMediaScanner(permissionService: permService, logger: logger);
});

// --- Data Source Providers ---

final localTrackDataSourceProvider = Provider<LocalTrackDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalTrackDataSource(db);
});

final localPlaylistDataSourceProvider = Provider<LocalPlaylistDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalPlaylistDataSource(db);
});

final localHistoryDataSourceProvider = Provider<LocalHistoryDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalHistoryDataSource(db);
});

final remoteMusicDataSourceProvider = Provider<RemoteMusicDataSource>((ref) {
  final logger = ref.watch(loggerProvider);
  return RemoteMusicDataSourceImpl(logger: logger);
});

// --- Repository Providers ---

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final localDataSource = ref.watch(localTrackDataSourceProvider);
  final remoteDataSource = ref.watch(remoteMusicDataSourceProvider);
  final logger = ref.watch(loggerProvider);
  final repo = TrackRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    logger: logger,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final localDataSource = ref.watch(localPlaylistDataSourceProvider);
  final logger = ref.watch(loggerProvider);
  return PlaylistRepositoryImpl(
    localDataSource: localDataSource,
    logger: logger,
  );
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final localDataSource = ref.watch(localHistoryDataSourceProvider);
  final logger = ref.watch(loggerProvider);
  return HistoryRepositoryImpl(
    localDataSource: localDataSource,
    logger: logger,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  final logger = ref.watch(loggerProvider);
  return SettingsRepositoryImpl(
    store: store,
    logger: logger,
  );
});

final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  final engine = ref.watch(audioEngineProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  final trackRepo = ref.watch(trackRepositoryProvider);
  final logger = ref.watch(loggerProvider);
  final repo = PlaybackRepositoryImpl(
    audioEngine: engine,
    historyRepository: historyRepo,
    trackRepository: trackRepo,
    logger: logger,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  return UserProfileRepositoryImpl(store);
});

final equalizerRepositoryProvider = Provider<EqualizerRepository>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  return EqualizerRepositoryImpl(store);
});
