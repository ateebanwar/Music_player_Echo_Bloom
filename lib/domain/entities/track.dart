import 'package:equatable/equatable.dart';

/// Track source indicator: whether the track is stored locally on device,
/// cached, downloaded, or remote.
enum TrackSourceType {
  localFile,
  cached,
  downloaded,
  remoteStream,
}

/// Core immutable domain representation of a music track.
/// Contains pure business data without UI or framework dependencies.
class Track extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final String mediaUri; // file path or remote URI
  final TrackSourceType sourceType;
  final String? artworkUri;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final int? bitRate;
  final int? sampleRate;
  final int fileSize; // in bytes
  final DateTime dateAdded;
  final DateTime? dateModified;
  final bool isFavorite;
  final String? remoteProvider; // e.g. 'jiosaavn', 'gaana'
  final String? remoteProviderId; // e.g. raw provider ID
  final String? remotePermaUrl; // permanent song reference URL

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.mediaUri,
    this.sourceType = TrackSourceType.localFile,
    this.artworkUri,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.bitRate,
    this.sampleRate,
    this.fileSize = 0,
    required this.dateAdded,
    this.dateModified,
    this.isFavorite = false,
    this.remoteProvider,
    this.remoteProviderId,
    this.remotePermaUrl,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? mediaUri,
    TrackSourceType? sourceType,
    String? artworkUri,
    int? trackNumber,
    int? discNumber,
    int? year,
    String? genre,
    int? bitRate,
    int? sampleRate,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? dateModified,
    bool? isFavorite,
    String? remoteProvider,
    String? remoteProviderId,
    String? remotePermaUrl,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      mediaUri: mediaUri ?? this.mediaUri,
      sourceType: sourceType ?? this.sourceType,
      artworkUri: artworkUri ?? this.artworkUri,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      bitRate: bitRate ?? this.bitRate,
      sampleRate: sampleRate ?? this.sampleRate,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      isFavorite: isFavorite ?? this.isFavorite,
      remoteProvider: remoteProvider ?? this.remoteProvider,
      remoteProviderId: remoteProviderId ?? this.remoteProviderId,
      remotePermaUrl: remotePermaUrl ?? this.remotePermaUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        duration,
        mediaUri,
        sourceType,
        artworkUri,
        trackNumber,
        discNumber,
        year,
        genre,
        bitRate,
        sampleRate,
        fileSize,
        dateAdded,
        dateModified,
        isFavorite,
        remoteProvider,
        remoteProviderId,
        remotePermaUrl,
      ];
}
