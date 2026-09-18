import 'package:sound_foundry/core/errors/app_exception.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/data/local/database/migration.dart';
import 'package:sound_foundry/data/local/database/migrations/v1_initial_schema.dart';
import 'package:sound_foundry/data/local/database/migrations/v2_online_tracks_schema.dart';
import 'package:sqflite/sqflite.dart';

/// Coordinates execution of versioned database migrations.
/// Ensures idempotent, ordered schema progression.
class DatabaseMigrator {
  final List<Migration> _migrations;
  final AppLogger? _logger;

  DatabaseMigrator({
    List<Migration>? migrations,
    AppLogger? logger,
  })  : _migrations = migrations ?? [V1InitialSchema(), V2OnlineTracksSchema()],
        _logger = logger;

  int get latestVersion =>
      _migrations.isEmpty ? 1 : _migrations.map((m) => m.version).reduce((a, b) => a > b ? a : b);

  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    _logger?.info('Starting database migration: v$oldVersion -> v$newVersion', tag: 'DatabaseMigrator');

    final pendingMigrations = _migrations
        .where((m) => m.version > oldVersion && m.version <= newVersion)
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in pendingMigrations) {
      try {
        _logger?.debug('Executing migration v${migration.version}...', tag: 'DatabaseMigrator');
        await migration.up(db);
      } catch (e, stack) {
        _logger?.error(
          'Migration v${migration.version} failed',
          tag: 'DatabaseMigrator',
          error: e,
          stackTrace: stack,
        );
        throw AppDatabaseException(
          message: 'Failed to apply migration v${migration.version}: $e',
          originalException: e,
          stackTrace: stack,
        );
      }
    }

    _logger?.info('Database migration completed successfully', tag: 'DatabaseMigrator');
  }
}
