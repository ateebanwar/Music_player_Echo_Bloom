import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';

class FavoritesState extends Equatable {
  final bool isLoading;
  final List<Track> favorites;
  final String? errorMessage;

  const FavoritesState({
    this.isLoading = false,
    this.favorites = const [],
    this.errorMessage,
  });

  FavoritesState copyWith({
    bool? isLoading,
    List<Track>? favorites,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      favorites: favorites ?? this.favorites,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, favorites, errorMessage];
}

class FavoritesController extends StateNotifier<FavoritesState> {
  final TrackRepository _trackRepository;

  FavoritesController(this._trackRepository) : super(const FavoritesState());

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _trackRepository.getFavoriteTracks();

    state = state.copyWith(
      isLoading: false,
      favorites: result.valueOrNull ?? state.favorites,
      errorMessage: result.failureOrNull?.message,
    );
  }

  Future<bool> toggleFavorite(Track track) async {
    final result = await _trackRepository.toggleFavorite(track.id, track);
    return result.when(
      ok: (isNowFavorite) {
        if (isNowFavorite) {
          state = state.copyWith(favorites: [...state.favorites, track.copyWith(isFavorite: true)]);
        } else {
          state = state.copyWith(favorites: state.favorites.where((t) => t.id != track.id).toList());
        }
        return isNowFavorite;
      },
      err: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return track.isFavorite;
      },
    );
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final trackRepo = ref.watch(trackRepositoryProvider);
  return FavoritesController(trackRepo);
});
