import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/infrastructure/permissions/permission_service.dart';
import 'package:sound_foundry/infrastructure/platform/audio_metadata_extractor.dart';

/// Progress event emitted during media library scans.
class ScanProgress extends Equatable {
  final int scannedFiles;
  final int totalFiles;
  final String? currentItem;
  final bool isCompleted;

  const ScanProgress({
    required this.scannedFiles,
    required this.totalFiles,
    this.currentItem,
    this.isCompleted = false,
  });

  double get percentage =>
      totalFiles > 0 ? (scannedFiles / totalFiles).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [scannedFiles, totalFiles, currentItem, isCompleted];
}

/// Abstract contract for scanning local device audio storage / MediaStore.
abstract class MediaScanner {
  /// Stream reporting scan progress.
  Stream<ScanProgress> get progressStream;

  /// Starts an incremental media scan.
  Future<Result<List<Track>, Failure>> scanLibrary({
    List<String>? directories,
    bool fullRescan = false,
  });

  /// Cancels an ongoing scan.
  void cancelScan();
}

/// Robust, production-grade MediaScanner supporting Android MediaStore ContentResolver and scoped storage.
class DefaultMediaScanner implements MediaScanner {
  final PermissionService? _permissionService;
  final AppLogger? _logger;
  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();

  static const MethodChannel _mediaStoreChannel =
      MethodChannel('com.antigravity.sound_foundry/media_store');

  bool _isCancelled = false;

  DefaultMediaScanner({
    PermissionService? permissionService,
    AppLogger? logger,
  })  : _permissionService = permissionService,
        _logger = logger;

  @override
  Stream<ScanProgress> get progressStream => _progressController.stream;

  static const _supportedAudioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
  };

  @override
  Future<Result<List<Track>, Failure>> scanLibrary({
    List<String>? directories,
    bool fullRescan = false,
  }) async {
    if (kIsWeb) {
      _logger?.info('Media scanning skipped on Web platform.', tag: 'MediaScanner');
      return const Result.ok([]);
    }

    _isCancelled = false;
    _logger?.info('Starting local device media scan...', tag: 'MediaScanner');

    try {
      // 1. Request and verify storage/audio permissions
      if (_permissionService != null) {
        final permState = await _permissionService.requestAudioPermission();
        _logger?.info('Permission status: $permState', tag: 'MediaScanner');
        if (permState == PermissionState.denied ||
            permState == PermissionState.permanentlyDenied) {
          _logger?.warning('Audio permission denied by user', tag: 'MediaScanner');
          return const Result.ok([]);
        }
      }

      final discoveredTracks = <Track>[];

      // 2. Primary Android Path: Direct Android MediaStore ContentResolver
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          final List<dynamic>? rawList =
              await _mediaStoreChannel.invokeMethod<List<dynamic>>('queryAudioFiles');

          if (rawList != null && rawList.isNotEmpty) {
            _logger?.info('Android MediaStore returned ${rawList.length} media items', tag: 'MediaScanner');
            final total = rawList.length;

            for (var i = 0; i < total; i++) {
              if (_isCancelled) {
                _logger?.warning('Media scan cancelled by user', tag: 'MediaScanner');
                break;
              }

              final item = Map<String, dynamic>.from(rawList[i] as Map);
              final id = item['id']?.toString() ?? '$i';
              final title = (item['title'] as String?)?.trim() ?? 'Unknown Title';
              final artist = (item['artist'] as String?)?.trim() ?? 'Unknown Artist';
              final album = (item['album'] as String?)?.trim() ?? 'Unknown Album';
              final durationMs = (item['durationMs'] as num?)?.toInt() ?? 0;
              final filePath = (item['filePath'] as String?) ?? '';
              final contentUri = (item['contentUri'] as String?) ?? '';
              final trackNumber = (item['trackNumber'] as num?)?.toInt();
              final year = (item['year'] as num?)?.toInt();

              // Use content URI or verified file path as playable media URI
              final mediaUri = filePath.isNotEmpty && File(filePath).existsSync()
                  ? filePath
                  : (contentUri.isNotEmpty ? contentUri : filePath);

              // Extract embedded artwork via native MediaMetadataRetriever (handles content URIs and files)
              String? artCachePath;
              try {
                final String? res = await _mediaStoreChannel.invokeMethod<String>('extractArtwork', {
                  'filePath': filePath,
                  'mediaUri': contentUri.isNotEmpty ? contentUri : filePath,
                });
                if (res != null && res.isNotEmpty && File(res).existsSync()) {
                  artCachePath = res;
                }
              } catch (_) {}

              final finalArtwork = artCachePath ?? 'assets/images/default_artwork.jpg';

              final track = Track(
                id: 'media-$id',
                title: title.isNotEmpty ? title : 'Unknown Title',
                artist: artist.isNotEmpty ? artist : 'Unknown Artist',
                album: album.isNotEmpty ? album : 'Unknown Album',
                duration: durationMs > 0
                    ? Duration(milliseconds: durationMs)
                    : const Duration(minutes: 3, seconds: 30),
                mediaUri: mediaUri,
                artworkUri: finalArtwork,
                trackNumber: trackNumber,
                year: year,
                dateAdded: DateTime.now(),
                isFavorite: false,
              );

              discoveredTracks.add(track);

              if (!_progressController.isClosed) {
                _progressController.add(ScanProgress(
                  scannedFiles: i + 1,
                  totalFiles: total,
                  currentItem: track.title,
                  isCompleted: (i + 1) == total,
                ));
              }

              // Yield to prevent UI frame hitching during large library indexing
              if (i % 8 == 0) {
                await Future<void>.delayed(const Duration(milliseconds: 1));
              }
            }
          }
        } catch (e) {
          _logger?.warning('Native MediaStore query failed, falling back to disk traversal: $e', tag: 'MediaScanner');
        }
      }

      // 3. Secondary Fallback Path: Direct file directory scanning (for Desktop / iOS / tests)
      if (discoveredTracks.isEmpty && !_isCancelled) {
        final discoveredFiles = <File>[];
        final targetDirs = <Directory>[];

        if (directories != null && directories.isNotEmpty) {
          for (final dirPath in directories) {
            final d = Directory(dirPath);
            if (await d.exists()) targetDirs.add(d);
          }
        } else {
          targetDirs.addAll(await _resolveDefaultScanDirectories());
        }

        for (final dir in targetDirs) {
          if (_isCancelled) break;
          await _scanDirectoryForAudio(dir, discoveredFiles, maxDepth: 4);
        }

        if (discoveredFiles.isNotEmpty) {
          final total = discoveredFiles.length;
          _logger?.info('Directory scan found $total audio files', tag: 'MediaScanner');

          for (var i = 0; i < total; i++) {
            if (_isCancelled) break;
            final file = discoveredFiles[i];
            try {
              final metadata = await AudioMetadataExtractor.extractFromFile(file);
              final track = Track(
                id: 'local-${file.path.hashCode.abs()}',
                title: metadata.title,
                artist: metadata.artist,
                album: metadata.album,
                duration: metadata.duration,
                mediaUri: file.path,
                artworkUri: metadata.artworkFilePath ?? 'assets/images/default_artwork.jpg',
                trackNumber: metadata.trackNumber,
                year: metadata.year,
                genre: metadata.genre,
                dateAdded: DateTime.now(),
                isFavorite: false,
              );

              discoveredTracks.add(track);

              if (!_progressController.isClosed) {
                _progressController.add(ScanProgress(
                  scannedFiles: i + 1,
                  totalFiles: total,
                  currentItem: track.title,
                  isCompleted: (i + 1) == total,
                ));
              }
            } catch (_) {}

            if (i % 5 == 0) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
          }
        }
      }

      _logger?.info('Media scan completed. Indexed ${discoveredTracks.length} tracks.', tag: 'MediaScanner');
      return Result.ok(discoveredTracks);
    } catch (e, stack) {
      _logger?.error('Media scan encountered error', tag: 'MediaScanner', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Media scan failed: $e', cause: e));
    }
  }

  Future<List<Directory>> _resolveDefaultScanDirectories() async {
    final dirs = <Directory>[];

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final standardAndroidPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/media',
        '/sdcard/Music',
        '/sdcard/Download',
      ];

      for (final p in standardAndroidPaths) {
        final d = Directory(p);
        if (await d.exists()) dirs.add(d);
      }

      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
        if (extDirs != null) {
          for (final d in extDirs) {
            if (await d.exists() && !dirs.any((existing) => existing.path == d.path)) {
              dirs.add(d);
            }
          }
        }
      } catch (_) {}
    } else if (!kIsWeb) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        dirs.add(docs);
        final downloads = await getDownloadsDirectory();
        if (downloads != null && await downloads.exists()) dirs.add(downloads);
      } catch (_) {}
    }

    return dirs;
  }

  Future<void> _scanDirectoryForAudio(
    Directory dir,
    List<File> results, {
    int currentDepth = 0,
    int maxDepth = 4,
  }) async {
    if (currentDepth > maxDepth || _isCancelled) return;

    try {
      final entries = dir.listSync(followLinks: false);
      for (final entry in entries) {
        if (_isCancelled) break;
        if (entry is File) {
          final ext = p.extension(entry.path).toLowerCase();
          if (_supportedAudioExtensions.contains(ext)) {
            results.add(entry);
          }
        } else if (entry is Directory) {
          final name = p.basename(entry.path);
          if (!name.startsWith('.') &&
              name != 'Android' &&
              name != 'thumbnails' &&
              name != 'cache') {
            await _scanDirectoryForAudio(
              entry,
              results,
              currentDepth: currentDepth + 1,
              maxDepth: maxDepth,
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  void cancelScan() {
    _isCancelled = true;
  }
}
