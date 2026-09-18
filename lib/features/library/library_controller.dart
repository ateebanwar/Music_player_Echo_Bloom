import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/features/library/library_state.dart';
import 'package:sound_foundry/infrastructure/platform/media_scanner.dart';

/// StateNotifier controlling the Music Library feature state.
class LibraryController extends StateNotifier<LibraryState> {
  final TrackRepository _trackRepository;
  final MediaScanner? _mediaScanner;

  LibraryController(
    this._trackRepository, {
    MediaScanner? mediaScanner,
  })  : _mediaScanner = mediaScanner,
        super(const LibraryState());

  /// Loads initial page of tracks, artists, and albums.
  Future<void> loadLibrary({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    var trackRes = await _trackRepository.getTracks(const PageQuery(offset: 0, limit: 100));

    // If local tracks count is low/empty and scanner is available, perform discovery
    if ((trackRes.valueOrNull?.items.isEmpty ?? true) && _mediaScanner != null) {
      final scanRes = await _mediaScanner.scanLibrary();
      final discoveredTracks = scanRes.valueOrNull;
      if (discoveredTracks != null && discoveredTracks.isNotEmpty) {
        await _trackRepository.upsertTracks(discoveredTracks);
        trackRes = await _trackRepository.getTracks(const PageQuery(offset: 0, limit: 100));
      }
    }

    final artistRes = await _trackRepository.getArtists();
    final albumRes = await _trackRepository.getAlbums();

    state = state.copyWith(
      isLoading: false,
      tracks: trackRes.valueOrNull ?? (refresh ? const PaginatedList.empty() : state.tracks),
      artists: artistRes.valueOrNull ?? (refresh ? const [] : state.artists),
      albums: albumRes.valueOrNull ?? (refresh ? const [] : state.albums),
      errorMessage: trackRes.failureOrNull?.message,
    );
  }

  /// Triggers a manual full library rescan.
  Future<void> rescanLibrary() async {
    if (_mediaScanner == null) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final scanRes = await _mediaScanner.scanLibrary(fullRescan: true);
    final discoveredTracks = scanRes.valueOrNull;
    if (discoveredTracks != null && discoveredTracks.isNotEmpty) {
      await _trackRepository.upsertTracks(discoveredTracks);
    }

    var trackRes = await _trackRepository.getTracks(const PageQuery(offset: 0, limit: 100));
    final artistRes = await _trackRepository.getArtists();
    final albumRes = await _trackRepository.getAlbums();

    state = state.copyWith(
      isLoading: false,
      tracks: trackRes.valueOrNull ?? state.tracks,
      artists: artistRes.valueOrNull ?? state.artists,
      albums: albumRes.valueOrNull ?? state.albums,
      errorMessage: scanRes.failureOrNull?.message ?? trackRes.failureOrNull?.message,
    );
  }

  /// Loads next page of tracks (pagination).
  Future<void> loadMoreTracks() async {
    if (state.isLoading || !state.tracks.hasMore) return;

    final nextQuery = PageQuery(
      offset: state.tracks.nextPageOffset,
      limit: state.tracks.limit,
    );

    final result = await _trackRepository.getTracks(nextQuery);

    result.when(
      ok: (newPage) {
        final combinedItems = [...state.tracks.items, ...newPage.items];
        state = state.copyWith(
          tracks: PaginatedList(
            items: combinedItems,
            totalCount: newPage.totalCount,
            offset: newPage.offset,
            limit: newPage.limit,
          ),
        );
      },
      err: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }
}
