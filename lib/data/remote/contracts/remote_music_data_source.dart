import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Contract for future remote music catalog and streaming endpoints.
/// Allows plug-and-play remote source addition without touching local library logic.
abstract class RemoteMusicDataSource {
  /// Fetches remote tracks page.
  Future<PaginatedList<Track>> fetchTracks(PageQuery query);

  /// Fetches a specific remote track by ID.
  Future<Track?> fetchTrackById(String id);

  /// Searches remote music catalog.
  Future<List<Track>> searchRemoteCatalog(String query);

  /// Fetches artist catalog.
  Future<List<Artist>> fetchArtists();

  /// Fetches album catalog.
  Future<List<Album>> fetchAlbums();

  /// Fetches remote stream URL or signing token for playback.
  Future<String> resolveStreamUri(String trackIdOrUri, [Track? track]);
}
