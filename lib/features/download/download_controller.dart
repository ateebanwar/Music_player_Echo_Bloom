import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';

class DownloadState extends Equatable {
  final List<Track> downloadedTracks;
  final Set<String> downloadingTrackIds;
  final bool isLoading;
  final String? errorMessage;

  const DownloadState({
    this.downloadedTracks = const [],
    this.downloadingTrackIds = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  DownloadState copyWith({
    List<Track>? downloadedTracks,
    Set<String>? downloadingTrackIds,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadState(
      downloadedTracks: downloadedTracks ?? this.downloadedTracks,
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [downloadedTracks, downloadingTrackIds, isLoading, errorMessage];
}

class DownloadController extends StateNotifier<DownloadState> {
  final TrackRepository _trackRepository;
  final AppLogger? _logger;
  final http.Client _client;

  DownloadController(
    this._trackRepository, {
    AppLogger? logger,
    http.Client? client,
  })  : _logger = logger,
        _client = client ?? http.Client(),
        super(const DownloadState()) {
    loadDownloadedTracks();
  }

  Future<void> loadDownloadedTracks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _trackRepository.getDownloadedTracks();
    if (result.isOk) {
      state = state.copyWith(
        downloadedTracks: result.valueOrNull ?? [],
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message ?? 'Failed to load downloaded songs',
      );
    }
  }

  bool isTrackDownloaded(Track track) {
    return state.downloadedTracks.any((t) =>
        t.id == track.id ||
        (t.remoteProvider != null &&
            t.remoteProvider == track.remoteProvider &&
            t.remoteProviderId != null &&
            t.remoteProviderId == track.remoteProviderId));
  }

  bool isDownloading(String trackId) {
    return state.downloadingTrackIds.contains(trackId);
  }

  Future<bool> downloadTrack(Track track) async {
    if (isTrackDownloaded(track)) {
      _logger?.info('Track ${track.title} already downloaded', tag: 'DownloadController');
      return true;
    }

    if (isDownloading(track.id)) {
      _logger?.info('Track ${track.title} download already in progress', tag: 'DownloadController');
      return false;
    }

    // Add to active downloading set
    final updatedDownloading = Set<String>.from(state.downloadingTrackIds)..add(track.id);
    state = state.copyWith(downloadingTrackIds: updatedDownloading, clearError: true);

    File? tempFile;
    try {
      _logger?.info('Resolving stream URI for download: ${track.title}', tag: 'DownloadController');
      final streamUrl = await _trackRepository.resolveStreamUri(
        track.mediaUri.isNotEmpty ? track.mediaUri : track.id,
        track,
      );

      if (streamUrl.isEmpty || (!streamUrl.startsWith('http://') && !streamUrl.startsWith('https://'))) {
        throw Exception('Playable stream URL could not be resolved');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      if (!downloadDir.existsSync()) {
        await downloadDir.create(recursive: true);
      }

      final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      tempFile = File('${downloadDir.path}/$safeId.part');
      final finalFile = File('${downloadDir.path}/$safeId.m4a');

      if (tempFile.existsSync()) {
        await tempFile.delete();
      }

      _logger?.info('Downloading stream from $streamUrl to ${tempFile.path}', tag: 'DownloadController');
      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36';

      final response = await _client.send(request);
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download HTTP error: ${response.statusCode}');
      }

      final sink = tempFile.openWrite();
      await response.stream.pipe(sink);
      await sink.flush();
      await sink.close();

      final bytesWritten = await tempFile.length();
      if (bytesWritten < 1024) {
        if (tempFile.existsSync()) await tempFile.delete();
        throw Exception('Downloaded file is too small or incomplete ($bytesWritten bytes)');
      }

      // Atomic rename to final file destination
      if (finalFile.existsSync()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);

      // Save persistent record in SQLite
      final downloadedTrack = track.copyWith(
        mediaUri: finalFile.path,
        sourceType: TrackSourceType.downloaded,
        fileSize: bytesWritten,
        dateAdded: DateTime.now(),
      );

      await _trackRepository.upsertTracks([downloadedTrack]);
      await loadDownloadedTracks();

      _logger?.info('Successfully downloaded and persisted: ${track.title}', tag: 'DownloadController');
      return true;
    } catch (e, stack) {
      _logger?.error('Download failed for ${track.title}', tag: 'DownloadController', error: e, stackTrace: stack);
      if (tempFile != null && tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      state = state.copyWith(errorMessage: 'Download failed: $e');
      return false;
    } finally {
      final finalDownloading = Set<String>.from(state.downloadingTrackIds)..remove(track.id);
      state = state.copyWith(downloadingTrackIds: finalDownloading);
    }
  }

  Future<void> deleteDownload(Track track) async {
    try {
      final file = File(track.mediaUri);
      if (file.existsSync()) {
        await file.delete();
      }
      await _trackRepository.deleteTracks([track.id]);
      await loadDownloadedTracks();
      _logger?.info('Deleted download: ${track.title}', tag: 'DownloadController');
    } catch (e, stack) {
      _logger?.error('Failed to delete download: ${track.title}', tag: 'DownloadController', error: e, stackTrace: stack);
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>((ref) {
  final trackRepo = ref.watch(trackRepositoryProvider);
  final logger = ref.watch(loggerProvider);
  return DownloadController(trackRepo, logger: logger);
});
