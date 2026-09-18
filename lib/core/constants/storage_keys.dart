/// Centralized key constants for local storage, settings, and database metadata.
/// Prevents magic strings across the codebase.
abstract final class StorageKeys {
  static const String databaseName = 'sound_foundry_v1.db';
  static const int databaseVersion = 1;

  // Settings keys
  static const String keyAudioQuality = 'settings_audio_quality';
  static const String keyRepeatMode = 'settings_repeat_mode';
  static const String keyShuffleMode = 'settings_shuffle_mode';
  static const String keyVolumeLevel = 'settings_volume_level';
  static const String keyLastPlayedTrackId = 'playback_last_played_track_id';
  static const String keyLastPlaybackPositionMs = 'playback_last_position_ms';
  static const String keyAppThemeMode = 'settings_theme_mode';
}
