import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';

class SearchState extends Equatable {
  final String query;
  final bool isSearching;
  final List<Track> localResults;
  final List<Track> remoteResults;
  final String? errorMessage;
  final String? statusMessage;

  const SearchState({
    this.query = '',
    this.isSearching = false,
    this.localResults = const [],
    this.remoteResults = const [],
    this.errorMessage,
    this.statusMessage,
  });

  SearchState copyWith({
    String? query,
    bool? isSearching,
    List<Track>? localResults,
    List<Track>? remoteResults,
    String? errorMessage,
    String? statusMessage,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      localResults: localResults ?? this.localResults,
      remoteResults: remoteResults ?? this.remoteResults,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
        query,
        isSearching,
        localResults,
        remoteResults,
        errorMessage,
        statusMessage,
      ];
}

class SearchController extends StateNotifier<SearchState> {
  final TrackRepository _trackRepository;
  AppMode _appMode;
  Timer? _debounceTimer;
  int _searchSequence = 0;

  SearchController(this._trackRepository, [this._appMode = AppMode.offline])
      : super(const SearchState());

  void setAppMode(AppMode mode) {
    if (_appMode != mode) {
      _appMode = mode;
      if (state.query.isNotEmpty) {
        search(state.query, immediate: true);
      }
    }
  }

  Future<void> search(String query, {bool immediate = false}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _debounceTimer?.cancel();
      state = const SearchState();
      return;
    }

    _debounceTimer?.cancel();

    if (immediate || _appMode == AppMode.offline) {
      await _executeSearch(trimmed);
    } else {
      // Debounce network requests while typing in online mode
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _executeSearch(trimmed);
      });
    }
  }

  Future<void> _executeSearch(String trimmed) async {
    final sequence = ++_searchSequence;

    state = state.copyWith(
      query: trimmed,
      isSearching: true,
      statusMessage: _appMode == AppMode.online ? 'Searching online catalog...' : 'Searching library...',
      clearError: true,
    );

    if (_appMode == AppMode.offline) {
      // STRICT OFFLINE SEARCH: Pure local SQLite discovery, 0 network calls
      final localRes = await _trackRepository.searchTracks(trimmed);
      if (sequence != _searchSequence) return; // Discard stale response

      state = state.copyWith(
        isSearching: false,
        localResults: localRes.valueOrNull ?? [],
        remoteResults: const [],
        errorMessage: localRes.failureOrNull?.message,
        clearStatus: true,
      );
    } else {
      // ONLINE SEARCH: JioSaavn primary with Gaana fallback
      final remoteRes = await _trackRepository.searchRemoteTracks(trimmed);
      if (sequence != _searchSequence) return; // Discard stale response

      final tracks = remoteRes.valueOrNull ?? [];
      final failure = remoteRes.failureOrNull;

      state = state.copyWith(
        isSearching: false,
        remoteResults: tracks,
        localResults: const [],
        errorMessage: failure != null && tracks.isEmpty
            ? 'Unable to search online music right now. Please check your network connection.'
            : null,
        clearStatus: true,
      );
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final trackRepo = ref.watch(trackRepositoryProvider);
  final settings = ref.watch(settingsControllerProvider);
  final controller = SearchController(trackRepo, settings.appMode);
  ref.listen<SettingsState>(settingsControllerProvider, (prev, next) {
    if (prev?.appMode != next.appMode) {
      controller.setAppMode(next.appMode);
    }
  });
  return controller;
});

/// Reactive trigger for orchestrating automatic search focus and keyboard opening
/// strictly when transitioning from Offline to Online mode.
final searchFocusTriggerProvider = StateProvider<bool>((ref) => false);

