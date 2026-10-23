import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Contract for remote music catalog, discovery, and streaming endpoints.
/// Supports search, artist discovery, album lookups, and discovery playlists.
abstract class RemoteMusicDataSource {
  /// Fetches remote tracks page.
  Future<PaginatedList<Track>> fetchTracks(PageQuery query);

  /// Fetches a specific remote track by ID.
  Future<Track?> fetchTrackById(String id);

  /// Searches remote music catalog.
  Future<List<Track>> searchRemoteCatalog(String query);

  /// Fetches artist catalog or search artists.
  Future<List<Artist>> fetchArtists([String? query]);

  /// Fetches album catalog or search albums.
  Future<List<Album>> fetchAlbums([String? query]);

  /// Fetches tracks belonging to an album.
  Future<List<Track>> fetchAlbumTracks(String albumUrlOrId);

  /// Fetches curated / discovery playlists (Hindi, English, 1990s, classics).
  Future<List<Playlist>> fetchDiscoveryPlaylists();

  /// Fetches tracks belonging to a discovery playlist.
  Future<List<Track>> fetchPlaylistTracks(String playlistIdOrQuery);

  /// Fetches remote stream URL or signing token for playback.
  Future<String> resolveStreamUri(String trackIdOrUri, [Track? track]);
}

