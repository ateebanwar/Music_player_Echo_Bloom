import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Contract for user playlists and playlist item operations.
abstract class PlaylistRepository {
  /// Retrieves all user playlists.
  Future<Result<List<Playlist>, Failure>> getPlaylists();

  /// Retrieves a specific playlist by its [id].
  Future<Result<Playlist, Failure>> getPlaylistById(String id);

  /// Retrieves all tracks belonging to a playlist in ordering sequence.
  Future<Result<List<Track>, Failure>> getPlaylistTracks(String playlistId);

  /// Creates a new playlist with given [name] and optional [description].
  Future<Result<Playlist, Failure>> createPlaylist({
    required String name,
    String? description,
  });

  /// Updates playlist metadata.
  Future<Result<Playlist, Failure>> updatePlaylist(Playlist playlist);

  /// Deletes a playlist.
  Future<Result<void, Failure>> deletePlaylist(String playlistId);

  /// Adds a track to a playlist at the end of the order.
  Future<Result<void, Failure>> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    Track? track,
  });

  /// Removes a track from a playlist.
  Future<Result<void, Failure>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  /// Reorders a track within a playlist.
  Future<Result<void, Failure>> reorderTrack({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  });
}
