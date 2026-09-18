/// Execution priority for startup tasks.
enum StartupPriority {
  /// Must be executed synchronously before showing any UI (e.g. Config, Database migration).
  critical,

  /// Safe to initialize in the background after startup (e.g. media scanner, cache warmup).
  background,

  /// Initialized only upon explicit feature access.
  lazy,
}

/// Base contract for an isolated startup initialization task.
abstract class StartupTask {
  String get name;
  StartupPriority get priority;

  Future<void> execute();
}
