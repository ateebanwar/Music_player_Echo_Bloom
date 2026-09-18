import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';

void main() {
  group('Result<T, Failure>', () {
    test('Ok holds value and maps correctly', () {
      const result = Result<int, Failure>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, equals(42));
      expect(result.failureOrNull, isNull);

      final mapped = result.map((v) => 'Value: $v');
      expect(mapped.valueOrNull, equals('Value: 42'));
    });

    test('Err holds failure and maps error correctly', () {
      const failure = StorageFailure(message: 'Disk write failed');
      const result = Result<int, Failure>.err(failure);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final mapped = result.map((v) => 'Value: $v');
      expect(mapped.isErr, isTrue);
      expect(mapped.failureOrNull, equals(failure));
    });

    test('when pattern matches both branches correctly', () {
      const okResult = Result<String, Failure>.ok('data');
      const errResult = Result<String, Failure>.err(ValidationFailure(message: 'invalid'));

      final okBranch = okResult.when(
        ok: (v) => 'Success: $v',
        err: (f) => 'Error: ${f.message}',
      );

      final errBranch = errResult.when(
        ok: (v) => 'Success: $v',
        err: (f) => 'Error: ${f.message}',
      );

      expect(okBranch, equals('Success: data'));
      expect(errBranch, equals('Error: invalid'));
    });

    test('flatMap chains async operations properly', () async {
      const result = Result<int, Failure>.ok(10);

      final chained = await result.flatMap((val) async {
        return Result<String, Failure>.ok('Processed $val');
      });

      expect(chained.valueOrNull, equals('Processed 10'));
    });
  });
}
