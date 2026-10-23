import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/playlists/playlist_controller.dart';

final playlistControllerProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>((ref) {
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  return PlaylistController(playlistRepo);
});

/// Auto-disposing provider to retrieve the list of tracks for a given [playlistId].
/// Dynamically resolves user-created playlists, discovery playlists, albums, or downloaded collections.
final playlistTracksProvider =
    FutureProvider.autoDispose.family<List<Track>, String>((ref, playlistId) async {
  // 1. Discovery Playlist
  if (playlistId.startsWith('discovery_')) {
    try {
      final trackRepo = ref.watch(trackRepositoryProvider);
      final result = await trackRepo.getDiscoveryPlaylistTracks(playlistId);
      return result.valueOrNull ?? [];
    } catch (_) {
      return [];
    }
  }

  // 2. Album
  if (playlistId.startsWith('album_')) {
    try {
      final trackRepo = ref.watch(trackRepositoryProvider);
      final cleanAlbum = playlistId.replaceFirst('album_', '');
      final result = await trackRepo.getTracksByAlbum(cleanAlbum);
      return result.valueOrNull ?? [];
    } catch (_) {
      return [];
    }
  }

  // 3. Standard User Playlist
  try {
    final playlistRepo = ref.watch(playlistRepositoryProvider);
    final result = await playlistRepo.getPlaylistTracks(playlistId);
    if (result.isOk) {
      return result.valueOrNull ?? [];
    }
  } catch (_) {}

  // 4. Downloaded Playlist
  try {
    final downloadedDs = ref.watch(downloadedPlaylistDataSourceProvider);
    final downloadedTracks = await downloadedDs.getDownloadedPlaylistTracks(playlistId);
    if (downloadedTracks.isNotEmpty) {
      return downloadedTracks;
    }
  } catch (_) {}

  return [];
});

/// Provider for remote curated & discovery playlists (Hindi, 1990s, Pop, Romantic).
final discoveryPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  try {
    final trackRepo = ref.watch(trackRepositoryProvider);
    final res = await trackRepo.getDiscoveryPlaylists();
    return res.valueOrNull ?? [];
  } catch (_) {
    return [];
  }
});


