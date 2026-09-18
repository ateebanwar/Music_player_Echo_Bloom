import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Contract for track catalog access and manipulation.
/// Completely abstracts whether data is stored locally in SQLite,
/// scanned from MediaStore/filesystem, or retrieved via remote API.
abstract class TrackRepository {
  /// Retrieves a paginated slice of tracks.
  Future<Result<PaginatedList<Track>, Failure>> getTracks(PageQuery query);

  /// Retrieves a specific track by its stable unique [id].
  Future<Result<Track, Failure>> getTrackById(String id);

  /// Searches tracks by title, artist, or album in local storage.
  Future<Result<List<Track>, Failure>> searchTracks(String query);

  /// Searches remote online music catalog (JioSaavn / Gaana).
  Future<Result<List<Track>, Failure>> searchRemoteTracks(String query);

  /// Resolves playable stream URL for a remote track if needed.
  Future<String> resolveStreamUri(String trackIdOrUri, [Track? track]);

  /// Retrieves all artists.
  Future<Result<List<Artist>, Failure>> getArtists();

  /// Retrieves all albums.
  Future<Result<List<Album>, Failure>> getAlbums();

  /// Retrieves tracks belonging to a specific artist.
  Future<Result<List<Track>, Failure>> getTracksByArtist(String artistName);

  /// Retrieves tracks belonging to a specific album.
  Future<Result<List<Track>, Failure>> getTracksByAlbum(String albumName);

  /// Retrieves favorite tracks.
  Future<Result<List<Track>, Failure>> getFavoriteTracks();

  /// Retrieves downloaded offline tracks.
  Future<Result<List<Track>, Failure>> getDownloadedTracks();

  /// Toggles favorite status for a track.
  Future<Result<bool, Failure>> toggleFavorite(String trackId, [Track? track]);

  /// Batch inserts or updates tracks (used by library scanner / remote sync).
  Future<Result<int, Failure>> upsertTracks(List<Track> tracks);

  /// Deletes tracks by IDs.
  Future<Result<int, Failure>> deleteTracks(List<String> trackIds);

  /// Observes track count changes or library updates.
  Stream<int> watchTrackCount();
}
