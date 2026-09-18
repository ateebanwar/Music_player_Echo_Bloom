import 'package:equatable/equatable.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Immutable state for the local music library feature.
class LibraryState extends Equatable {
  final bool isLoading;
  final PaginatedList<Track> tracks;
  final List<Artist> artists;
  final List<Album> albums;
  final String? errorMessage;

  const LibraryState({
    this.isLoading = false,
    this.tracks = const PaginatedList(items: [], totalCount: 0, offset: 0, limit: 50),
    this.artists = const [],
    this.albums = const [],
    this.errorMessage,
  });

  LibraryState copyWith({
    bool? isLoading,
    PaginatedList<Track>? tracks,
    List<Artist>? artists,
    List<Album>? albums,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      tracks: tracks ?? this.tracks,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, tracks, artists, albums, errorMessage];
}
