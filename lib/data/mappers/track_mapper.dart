import 'package:sound_foundry/domain/entities/track.dart';

/// Maps between SQLite Database rows and [Track] domain entities.
abstract final class TrackMapper {
  static Track fromDbMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String?,
      duration: Duration(milliseconds: map['duration_ms'] as int),
      mediaUri: map['media_uri'] as String,
      sourceType: TrackSourceType.values[(map['source_type'] as int?) ?? 0],
      artworkUri: map['artwork_uri'] as String?,
      trackNumber: map['track_number'] as int?,
      discNumber: map['disc_number'] as int?,
      year: map['year'] as int?,
      genre: map['genre'] as String?,
      bitRate: map['bit_rate'] as int?,
      sampleRate: map['sample_rate'] as int?,
      fileSize: (map['file_size'] as int?) ?? 0,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
      dateModified: map['date_modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_modified'] as int)
          : null,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      remoteProvider: map['remote_provider'] as String?,
      remoteProviderId: map['remote_provider_id'] as String?,
      remotePermaUrl: map['remote_perma_url'] as String?,
    );
  }

  static Map<String, dynamic> toDbMap(Track track) {
    return <String, dynamic>{
      'id': track.id,
      'title': track.title,
      'artist': track.artist,
      'album': track.album,
      'duration_ms': track.duration.inMilliseconds,
      'media_uri': track.mediaUri,
      'source_type': track.sourceType.index,
      'artwork_uri': track.artworkUri,
      'track_number': track.trackNumber,
      'disc_number': track.discNumber,
      'year': track.year,
      'genre': track.genre,
      'bit_rate': track.bitRate,
      'sample_rate': track.sampleRate,
      'file_size': track.fileSize,
      'date_added': track.dateAdded.millisecondsSinceEpoch,
      'date_modified': track.dateModified?.millisecondsSinceEpoch,
      'is_favorite': track.isFavorite ? 1 : 0,
      'remote_provider': track.remoteProvider,
      'remote_provider_id': track.remoteProviderId,
      'remote_perma_url': track.remotePermaUrl,
    };
  }
}
