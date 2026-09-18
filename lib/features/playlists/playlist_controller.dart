import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/repositories/playlist_repository.dart';

class PlaylistState extends Equatable {
  final bool isLoading;
  final List<Playlist> playlists;
  final String? errorMessage;

  const PlaylistState({
    this.isLoading = false,
    this.playlists = const [],
    this.errorMessage,
  });

  PlaylistState copyWith({
    bool? isLoading,
    List<Playlist>? playlists,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlaylistState(
      isLoading: isLoading ?? this.isLoading,
      playlists: playlists ?? this.playlists,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, playlists, errorMessage];
}

class PlaylistController extends StateNotifier<PlaylistState> {
  final PlaylistRepository _playlistRepository;

  PlaylistController(this._playlistRepository) : super(const PlaylistState());

  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true, clearError: true);
    var result = await _playlistRepository.getPlaylists();

    // Auto-seed demo playlists if none exist
    if ((result.valueOrNull?.isEmpty ?? true)) {
      final p1 = await _playlistRepository.createPlaylist(
        name: 'Chill Vibes',
        description: 'Relaxing acoustic & indie tracks',
      );
      final p2 = await _playlistRepository.createPlaylist(
        name: 'Workout Hits',
        description: 'High energy beats & electronic',
      );
      if (p1.isOk && p2.isOk) {
        result = await _playlistRepository.getPlaylists();
      }
    }

    state = state.copyWith(
      isLoading: false,
      playlists: result.valueOrNull ?? state.playlists,
      errorMessage: result.failureOrNull?.message,
    );
  }

  Future<Playlist?> createPlaylist(String name, {String? description, Track? initialTrack}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final result = await _playlistRepository.createPlaylist(name: trimmedName, description: description);
    return result.when(
      ok: (newPlaylist) async {
        if (initialTrack != null) {
          await _playlistRepository.addTrackToPlaylist(
            playlistId: newPlaylist.id,
            trackId: initialTrack.id,
            track: initialTrack,
          );
        }
        await loadPlaylists();
        return newPlaylist;
      },
      err: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return null;
      },
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    final result = await _playlistRepository.deletePlaylist(playlistId);
    if (result.isOk) {
      state = state.copyWith(
        playlists: state.playlists.where((p) => p.id != playlistId).toList(),
      );
    }
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final result = await _playlistRepository.addTrackToPlaylist(
      playlistId: playlistId,
      trackId: track.id,
      track: track,
    );
    if (result.isOk) {
      await loadPlaylists();
      return true;
    } else {
      state = state.copyWith(errorMessage: result.failureOrNull?.message);
      return false;
    }
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final result = await _playlistRepository.removeTrackFromPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
    if (result.isOk) {
      await loadPlaylists();
      return true;
    } else {
      state = state.copyWith(errorMessage: result.failureOrNull?.message);
      return false;
    }
  }

  Future<void> playPlaylist(String playlistId, PlaybackRepository playbackRepo) async {
    final result = await _playlistRepository.getPlaylistTracks(playlistId);
    final tracks = result.valueOrNull;
    if (tracks != null && tracks.isNotEmpty) {
      await playbackRepo.setQueue(tracks, initialIndex: 0);
    }
  }
}
