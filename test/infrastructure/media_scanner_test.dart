import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/infrastructure/platform/media_scanner.dart';

void main() {
  group('DefaultMediaScanner Tests', () {
    late DefaultMediaScanner scanner;
    late Directory tempDir;

    setUp(() async {
      scanner = DefaultMediaScanner();
      tempDir = await Directory.systemTemp.createTemp('audio_scanner_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scanLibrary discovers local audio files from target directories', () async {
      // Create a test .mp3 file
      final testAudioFile = File('${tempDir.path}/test_song.mp3');
      await testAudioFile.writeAsBytes(List.filled(100, 0));

      final progressEvents = <ScanProgress>[];
      final sub = scanner.progressStream.listen(progressEvents.add);

      final result = await scanner.scanLibrary(directories: [tempDir.path]);

      expect(result.isOk, isTrue);
      final tracks = result.valueOrNull!;
      expect(tracks, isNotEmpty);
      expect(tracks.first.title, contains('test_song'));

      await sub.cancel();
    });

    test('scanLibrary returns empty list when no audio files exist in directory', () async {
      final result = await scanner.scanLibrary(directories: [tempDir.path]);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('cancelScan stops ongoing scan safely', () async {
      final future = scanner.scanLibrary(directories: [tempDir.path]);
      scanner.cancelScan();

      final result = await future;
      expect(result.isOk, isTrue);
    });
  });
}
