import 'package:sound_foundry/domain/entities/playlist.dart';

/// Maps between SQLite Database rows and [Playlist] domain entities.
abstract final class PlaylistMapper {
  static Playlist fromDbMap(Map<String, dynamic> map, {int trackCount = 0, Duration totalDuration = Duration.zero}) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      artworkUri: map['artwork_uri'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isSmartPlaylist: (map['is_smart'] as int? ?? 0) == 1,
      trackCount: (map['track_count'] as int?) ?? trackCount,
      totalDuration: map['total_duration_ms'] != null
          ? Duration(milliseconds: map['total_duration_ms'] as int)
          : totalDuration,
    );
  }

  static Map<String, dynamic> toDbMap(Playlist playlist) {
    return <String, dynamic>{
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'artwork_uri': playlist.artworkUri,
      'created_at': playlist.createdAt.millisecondsSinceEpoch,
      'updated_at': playlist.updatedAt.millisecondsSinceEpoch,
      'is_smart': playlist.isSmartPlaylist ? 1 : 0,
    };
  }
}
