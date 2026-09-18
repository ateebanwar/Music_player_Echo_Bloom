import 'package:sqflite/sqflite.dart';

/// Contract for a versioned database migration step.
/// Ensures safe, incremental, and testable database evolution.
abstract class Migration {
  /// Target version applied by this migration step.
  int get version;

  /// Executes the migration forward.
  Future<void> up(Database db);

  /// Reverses the migration (if applicable).
  Future<void> down(Database db);
}
