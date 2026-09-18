import 'package:equatable/equatable.dart';

/// Immutable domain representation of an Artist.
class Artist extends Equatable {
  final String id;
  final String name;
  final int trackCount;
  final int albumCount;
  final String? artworkUri;

  const Artist({
    required this.id,
    required this.name,
    this.trackCount = 0,
    this.albumCount = 0,
    this.artworkUri,
  });

  Artist copyWith({
    String? id,
    String? name,
    int? trackCount,
    int? albumCount,
    String? artworkUri,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      trackCount: trackCount ?? this.trackCount,
      albumCount: albumCount ?? this.albumCount,
      artworkUri: artworkUri ?? this.artworkUri,
    );
  }

  @override
  List<Object?> get props => [id, name, trackCount, albumCount, artworkUri];
}
