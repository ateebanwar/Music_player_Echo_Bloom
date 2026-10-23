import 'package:equatable/equatable.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

enum DownloadPlaylistStatus {
  queued,
  downloading,
  downloaded,
  partiallyDownloaded,
  failed,
}

/// Domain representation of a downloaded playlist collection in the offline library.
class DownloadedPlaylist extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? artworkUri;
  final String sourceType; // 'curated', 'album', 'user'
  final String? remoteId;
  final int totalTracks;
  final int downloadedTracks;
  final DownloadPlaylistStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Track> tracks;

  const DownloadedPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUri,
    this.sourceType = 'curated',
    this.remoteId,
    required this.totalTracks,
    required this.downloadedTracks,
    this.status = DownloadPlaylistStatus.downloaded,
    required this.createdAt,
    required this.updatedAt,
    this.tracks = const [],
  });

  bool get isFullyDownloaded => totalTracks > 0 && downloadedTracks >= totalTracks;

  Playlist toPlaylist() {
    return Playlist(
      id: id,
      name: name,
      description: description,
      artworkUri: artworkUri,
      trackCount: totalTracks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSmartPlaylist: true,
    );
  }

  DownloadedPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUri,
    String? sourceType,
    String? remoteId,
    int? totalTracks,
    int? downloadedTracks,
    DownloadPlaylistStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Track>? tracks,
  }) {
    return DownloadedPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUri: artworkUri ?? this.artworkUri,
      sourceType: sourceType ?? this.sourceType,
      remoteId: remoteId ?? this.remoteId,
      totalTracks: totalTracks ?? this.totalTracks,
      downloadedTracks: downloadedTracks ?? this.downloadedTracks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tracks: tracks ?? this.tracks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        artworkUri,
        sourceType,
        remoteId,
        totalTracks,
        downloadedTracks,
        status,
        createdAt,
        updatedAt,
        tracks,
      ];
}
