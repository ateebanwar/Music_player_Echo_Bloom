import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/core/errors/failures.dart';

void main() {
  group('Failure hierarchy', () {
    test('StorageFailure retains message and properties', () {
      const failure = StorageFailure(message: 'IO Error', code: 'IO_01');
      expect(failure.message, equals('IO Error'));
      expect(failure.code, equals('IO_01'));
      expect(failure.props, contains('IO Error'));
    });

    test('PermissionFailure handles permanently denied flag', () {
      const failure = PermissionFailure(
        message: 'Permission denied',
        isPermanentlyDenied: true,
      );
      expect(failure.isPermanentlyDenied, isTrue);
      expect(failure.props, contains(true));
    });

    test('MediaNotFoundFailure stores path', () {
      const failure = MediaNotFoundFailure(
        message: 'File not found',
        pathOrUri: '/storage/music/song.mp3',
      );
      expect(failure.pathOrUri, equals('/storage/music/song.mp3'));
    });
  });
}
