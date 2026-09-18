import 'package:equatable/equatable.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';

/// Represents a time-synced lyrics line.
class LyricLine extends Equatable {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  List<Object?> get props => [timestamp, text];
}

/// Domain model for lyrics (plain or synchronized).
class Lyrics extends Equatable {
  final String trackId;
  final String? plainLyrics;
  final List<LyricLine> syncedLines;
  final bool isSynced;

  const Lyrics({
    required this.trackId,
    this.plainLyrics,
    this.syncedLines = const [],
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [trackId, plainLyrics, syncedLines, isSynced];
}

/// Abstract contract for lazy lyrics resolution (offline tag extraction / online provider).
abstract class LyricsService {
  Future<Result<Lyrics, Failure>> getLyricsForTrack(String trackId);
}

/// Headless/Default implementation of [LyricsService].
class DefaultLyricsService implements LyricsService {
  @override
  Future<Result<Lyrics, Failure>> getLyricsForTrack(String trackId) async {
    return Result.ok(Lyrics(trackId: trackId));
  }
}
