import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/history_repository.dart';

class HistoryState extends Equatable {
  final bool isLoading;
  final List<PlayHistoryItem> recentItems;
  final List<Track> mostPlayed;
  final String? errorMessage;

  const HistoryState({
    this.isLoading = false,
    this.recentItems = const [],
    this.mostPlayed = const [],
    this.errorMessage,
  });

  HistoryState copyWith({
    bool? isLoading,
    List<PlayHistoryItem>? recentItems,
    List<Track>? mostPlayed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      recentItems: recentItems ?? this.recentItems,
      mostPlayed: mostPlayed ?? this.mostPlayed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, recentItems, mostPlayed, errorMessage];
}

class HistoryController extends StateNotifier<HistoryState> {
  final HistoryRepository _historyRepository;

  HistoryController(this._historyRepository) : super(const HistoryState());

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final recentRes = await _historyRepository.getRecentHistory(limit: 50);
    final mostPlayedRes = await _historyRepository.getMostPlayedTracks(limit: 20);

    state = state.copyWith(
      isLoading: false,
      recentItems: recentRes.valueOrNull ?? state.recentItems,
      mostPlayed: mostPlayedRes.valueOrNull ?? state.mostPlayed,
      errorMessage: recentRes.failureOrNull?.message,
    );
  }

  Future<void> clearHistory() async {
    await _historyRepository.clearHistory();
    state = const HistoryState();
  }
}

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
  final historyRepo = ref.watch(historyRepositoryProvider);
  return HistoryController(historyRepo);
});
