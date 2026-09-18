import 'package:equatable/equatable.dart';

/// Immutable domain representation of an Album.
class Album extends Equatable {
  final String id;
  final String title;
  final String artist;
  final int? year;
  final int trackCount;
  final String? artworkUri;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.year,
    this.trackCount = 0,
    this.artworkUri,
  });

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    int? year,
    int? trackCount,
    String? artworkUri,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      year: year ?? this.year,
      trackCount: trackCount ?? this.trackCount,
      artworkUri: artworkUri ?? this.artworkUri,
    );
  }

  @override
  List<Object?> get props => [id, title, artist, year, trackCount, artworkUri];
}
