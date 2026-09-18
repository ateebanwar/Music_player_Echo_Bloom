import 'package:flutter/foundation.dart';
import 'package:sound_foundry/core/constants/storage_keys.dart';
import 'package:sound_foundry/core/errors/app_exception.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/data/local/database/database_migrator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Database management service handling SQLite database connection,
/// path resolution, initialization, and lifecycle across Web, Desktop, and Mobile.
class AppDatabase {
  final DatabaseMigrator _migrator;
  final AppLogger? _logger;
  Database? _db;
  final String _databaseName;

  AppDatabase({
    DatabaseMigrator? migrator,
    AppLogger? logger,
    String databaseName = StorageKeys.databaseName,
  })  : _migrator = migrator ?? DatabaseMigrator(logger: logger),
        _logger = logger,
        _databaseName = databaseName;

  /// Returns active database instance or throws if not initialized.
  Database get database {
    final db = _db;
    if (db == null || !db.isOpen) {
      throw const AppDatabaseException(message: 'Database is not initialized or is closed.');
    }
    return db;
  }

  bool get isOpen => _db != null && _db!.isOpen;

  /// Initializes the SQLite database and executes pending migrations.
  Future<Database> initialize({String? inMemoryPath, DatabaseFactory? customFactory}) async {
    if (_db != null && _db!.isOpen) {
      return _db!;
    }

    try {
      DatabaseFactory factory;
      String dbPath;

      if (inMemoryPath != null) {
        factory = customFactory ?? (kIsWeb ? databaseFactoryFfiWebNoWebWorker : databaseFactoryFfi);
        dbPath = inMemoryPath;
      } else if (kIsWeb) {
        // Use databaseFactoryFfiWebNoWebWorker for zero-dependency browser compatibility
        factory = customFactory ?? databaseFactoryFfiWebNoWebWorker;
        dbPath = _databaseName;
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        factory = customFactory ?? databaseFactoryFfi;
        dbPath = inMemoryDatabasePath;
      } else {
        factory = customFactory ?? databaseFactory;
        final dbDirPath = await factory.getDatabasesPath();
        dbPath = '$dbDirPath/$_databaseName';
      }

      _logger?.info('Opening database at: $dbPath', tag: 'AppDatabase');

      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _migrator.latestVersion,
          onConfigure: (db) async {
            if (!kIsWeb) {
              await db.execute('PRAGMA foreign_keys = ON;');
            }
          },
          onCreate: (db, version) async {
            _logger?.info('Creating database v$version', tag: 'AppDatabase');
            await _migrator.migrate(db, 0, version);
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            _logger?.info('Upgrading database from v$oldVersion to v$newVersion', tag: 'AppDatabase');
            await _migrator.migrate(db, oldVersion, newVersion);
          },
        ),
      );

      _db = db;
      _logger?.info('Database initialized successfully', tag: 'AppDatabase');
      return db;
    } catch (e, stack) {
      _logger?.error('Failed to initialize database, trying web worker fallback', tag: 'AppDatabase', error: e, stackTrace: stack);
      // If Web direct worker failed, fallback to in-memory factory on web
      if (kIsWeb) {
        try {
          final fallbackDb = await databaseFactoryFfiWeb.openDatabase(
            inMemoryDatabasePath,
            options: OpenDatabaseOptions(
              version: _migrator.latestVersion,
              onCreate: (db, version) => _migrator.migrate(db, 0, version),
            ),
          );
          _db = fallbackDb;
          return fallbackDb;
        } catch (_) {}
      }

      throw AppDatabaseException(
        message: 'Could not initialize database: $e',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
      _logger?.info('Database connection closed', tag: 'AppDatabase');
    }
  }
}
