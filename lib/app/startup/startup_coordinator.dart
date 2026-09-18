import 'package:sound_foundry/app/startup/startup_task.dart';
import 'package:sound_foundry/core/errors/app_exception.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';

/// Coordinates application startup sequence.
/// Guarantees that critical tasks execute before app readiness,
/// while background and lazy tasks never block cold startup.
class StartupCoordinator {
  final List<StartupTask> _tasks;
  final AppLogger? _logger;
  bool _isCriticalComplete = false;

  StartupCoordinator({
    List<StartupTask>? tasks,
    AppLogger? logger,
  })  : _tasks = tasks ?? [],
        _logger = logger;

  bool get isCriticalComplete => _isCriticalComplete;

  void registerTask(StartupTask task) {
    _tasks.add(task);
  }

  /// Runs all [StartupPriority.critical] tasks sequentially.
  Future<void> runCriticalTasks() async {
    final stopwatch = Stopwatch()..start();
    _logger?.info('Executing critical startup sequence...', tag: 'StartupCoordinator');

    final criticalTasks = _tasks.where((t) => t.priority == StartupPriority.critical).toList();

    for (final task in criticalTasks) {
      try {
        _logger?.debug('Running startup task: ${task.name}', tag: 'StartupCoordinator');
        await task.execute();
      } catch (e, stack) {
        _logger?.error('Critical startup task failed: ${task.name}', tag: 'StartupCoordinator', error: e, stackTrace: stack);
        throw AppDatabaseException(
          message: 'Critical startup failure in task "${task.name}": $e',
          originalException: e,
          stackTrace: stack,
        );
      }
    }

    _isCriticalComplete = true;
    stopwatch.stop();
    _logger?.info('Critical startup completed in ${stopwatch.elapsedMilliseconds}ms', tag: 'StartupCoordinator');
  }

  /// Runs all [StartupPriority.background] tasks asynchronously.
  void runBackgroundTasks() {
    final backgroundTasks = _tasks.where((t) => t.priority == StartupPriority.background).toList();
    if (backgroundTasks.isEmpty) return;

    _logger?.info('Starting background startup tasks (${backgroundTasks.length})...', tag: 'StartupCoordinator');

    for (final task in backgroundTasks) {
      task.execute().then((_) {
        _logger?.debug('Background task finished: ${task.name}', tag: 'StartupCoordinator');
      }).catchError((dynamic e, StackTrace stack) {
        _logger?.warning('Background task "${task.name}" failed: $e', tag: 'StartupCoordinator', error: e, stackTrace: stack);
      });
    }
  }
}
