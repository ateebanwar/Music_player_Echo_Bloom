import 'package:equatable/equatable.dart';

/// Immutable domain representation of a Playlist.
class Playlist extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int trackCount;
  final Duration totalDuration;
  final String? artworkUri;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSmartPlaylist;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.trackCount = 0,
    this.totalDuration = Duration.zero,
    this.artworkUri,
    required this.createdAt,
    required this.updatedAt,
    this.isSmartPlaylist = false,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    int? trackCount,
    Duration? totalDuration,
    String? artworkUri,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSmartPlaylist,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trackCount: trackCount ?? this.trackCount,
      totalDuration: totalDuration ?? this.totalDuration,
      artworkUri: artworkUri ?? this.artworkUri,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmartPlaylist: isSmartPlaylist ?? this.isSmartPlaylist,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        trackCount,
        totalDuration,
        artworkUri,
        createdAt,
        updatedAt,
        isSmartPlaylist,
      ];
}

/// Represents an item entry within a playlist.
class PlaylistItem extends Equatable {
  final String playlistId;
  final String trackId;
  final int position;
  final DateTime addedAt;

  const PlaylistItem({
    required this.playlistId,
    required this.trackId,
    required this.position,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [playlistId, trackId, position, addedAt];
}
