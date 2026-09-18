import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/app/startup/startup_coordinator.dart';
import 'package:sound_foundry/app/startup/startup_task.dart';

class MockTask implements StartupTask {
  @override
  final String name;
  @override
  final StartupPriority priority;
  bool isExecuted = false;

  MockTask(this.name, this.priority);

  @override
  Future<void> execute() async {
    isExecuted = true;
  }
}

void main() {
  group('StartupCoordinator', () {
    test('runs critical tasks synchronously and marks complete', () async {
      final coordinator = StartupCoordinator();
      final criticalTask1 = MockTask('Task1', StartupPriority.critical);
      final criticalTask2 = MockTask('Task2', StartupPriority.critical);
      final backgroundTask = MockTask('Task3', StartupPriority.background);

      coordinator.registerTask(criticalTask1);
      coordinator.registerTask(criticalTask2);
      coordinator.registerTask(backgroundTask);

      expect(coordinator.isCriticalComplete, isFalse);

      await coordinator.runCriticalTasks();

      expect(coordinator.isCriticalComplete, isTrue);
      expect(criticalTask1.isExecuted, isTrue);
      expect(criticalTask2.isExecuted, isTrue);
      expect(backgroundTask.isExecuted, isFalse); // Not run in critical stage

      coordinator.runBackgroundTasks();
      // Allow async event loop
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(backgroundTask.isExecuted, isTrue);
    });
  });
}
