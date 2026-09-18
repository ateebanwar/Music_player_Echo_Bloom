import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/playlists/playlist_controller.dart';

final playlistControllerProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>((ref) {
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  return PlaylistController(playlistRepo);
});

/// Auto-disposing provider to retrieve the list of tracks for a given [playlistId].
final playlistTracksProvider =
    FutureProvider.autoDispose.family<List<Track>, String>((ref, playlistId) async {
  final playlistRepo = ref.watch(playlistRepositoryProvider);
  final result = await playlistRepo.getPlaylistTracks(playlistId);
  return result.valueOrNull ?? [];
});
