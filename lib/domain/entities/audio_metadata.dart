import 'package:equatable/equatable.dart';

/// Pure domain audio metadata extracted from files or remote sources.
class AudioMetadata extends Equatable {
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final int? bitRate;
  final int? sampleRate;
  final String? artworkPath;

  const AudioMetadata({
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.bitRate,
    this.sampleRate,
    this.artworkPath,
  });

  @override
  List<Object?> get props => [
        title,
        artist,
        album,
        duration,
        trackNumber,
        discNumber,
        year,
        genre,
        bitRate,
        sampleRate,
        artworkPath,
      ];
}
