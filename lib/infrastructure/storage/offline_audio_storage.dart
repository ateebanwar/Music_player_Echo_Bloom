import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/data/local/database/app_database.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/infrastructure/storage/web_blob_url.dart';
import 'package:sqflite/sqflite.dart';

/// Unified offline audio storage service.
/// Automatically abstracts between browser persistent IndexedDB blobs (Microsoft Edge/Web)
/// and device filesystem directories (Android/Windows).
class OfflineAudioStorage {
  final AppDatabase _appDatabase;
  final AppLogger? _logger;

  // Active object URLs generated on web (trackId -> blobUrl)
  final Map<String, String> _activeBlobUrls = {};

  OfflineAudioStorage({
    required AppDatabase appDatabase,
    AppLogger? logger,
  })  : _appDatabase = appDatabase,
        _logger = logger;

  /// Sanitizes track ID for safe filename usage on native platforms.
  static String safeFilename(String trackId) {
    return trackId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  /// Persists audio bytes offline.
  Future<String> saveAudio({
    required String trackId,
    required List<int> bytes,
    String mimeType = 'audio/mp4',
  }) async {
    final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (kIsWeb) {
      // Store in SQLite backed by IndexedDB on web
      final db = _appDatabase.database;
      await db.insert(
        'offline_audio_blobs',
        {
          'track_id': trackId,
          'audio_data': uint8Bytes,
          'mime_type': mimeType,
          'file_size': uint8Bytes.length,
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger?.info('Saved offline audio blob in IndexedDB for $trackId (${uint8Bytes.length} bytes)', tag: 'OfflineAudioStorage');
      return 'offline://track/$trackId';
    } else {
      // Store in device app documents directory on native platforms
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      if (!downloadDir.existsSync()) {
        await downloadDir.create(recursive: true);
      }

      final safeId = safeFilename(trackId);
      final finalFile = File('${downloadDir.path}/$safeId.m4a');

      await finalFile.writeAsBytes(uint8Bytes, flush: true);
      _logger?.info('Saved offline audio file at ${finalFile.path}', tag: 'OfflineAudioStorage');
      return finalFile.path;
    }
  }

  /// Resolves the playable URI for an offline downloaded track.
  Future<String?> resolvePlayableUri(Track track) async {
    if (kIsWeb) {
      if (_activeBlobUrls.containsKey(track.id)) {
        return _activeBlobUrls[track.id];
      }

      final db = _appDatabase.database;
      final rows = await db.query(
        'offline_audio_blobs',
        columns: ['audio_data', 'mime_type'],
        where: 'track_id = ?',
        whereArgs: [track.id],
      );

      if (rows.isNotEmpty) {
        final blobData = rows.first['audio_data'] as Uint8List?;
        final mimeType = (rows.first['mime_type'] as String?) ?? 'audio/mp4';

        if (blobData != null && blobData.isNotEmpty) {
          final blobUrl = WebBlobUrlHelper.createBlobUrl(blobData, mimeType);
          if (blobUrl != null) {
            _activeBlobUrls[track.id] = blobUrl;
            _logger?.info('Resolved offline blob object URL for ${track.title}', tag: 'OfflineAudioStorage');
            return blobUrl;
          }
        }
      }
      return null;
    } else {
      if (track.mediaUri.isNotEmpty && File(track.mediaUri).existsSync()) {
        return track.mediaUri;
      }

      // Check standard download directory fallback
      final appDir = await getApplicationDocumentsDirectory();
      final safeId = safeFilename(track.id);
      final fallbackFile = File('${appDir.path}/downloads/$safeId.m4a');
      if (fallbackFile.existsSync()) {
        return fallbackFile.path;
      }
      return null;
    }
  }

  /// Checks if offline audio exists for the given track.
  Future<bool> hasAudio(String trackId) async {
    if (kIsWeb) {
      final db = _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT 1 FROM offline_audio_blobs WHERE track_id = ? LIMIT 1',
        [trackId],
      );
      return rows.isNotEmpty;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final safeId = safeFilename(trackId);
      final file = File('${appDir.path}/downloads/$safeId.m4a');
      return file.existsSync();
    }
  }

  /// Gets the size in bytes of the offline stored audio.
  Future<int> getAudioSize(String trackId) async {
    if (kIsWeb) {
      final db = _appDatabase.database;
      final rows = await db.query(
        'offline_audio_blobs',
        columns: ['file_size'],
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      if (rows.isNotEmpty) {
        return (rows.first['file_size'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final safeId = safeFilename(trackId);
      final file = File('${appDir.path}/downloads/$safeId.m4a');
      if (file.existsSync()) {
        return file.lengthSync();
      }
      return 0;
    }
  }

  /// Deletes offline stored audio for the given track.
  Future<void> deleteAudio(String trackId) async {
    if (kIsWeb) {
      final blobUrl = _activeBlobUrls.remove(trackId);
      if (blobUrl != null) {
        WebBlobUrlHelper.revokeBlobUrl(blobUrl);
      }
      final db = _appDatabase.database;
      await db.delete('offline_audio_blobs', where: 'track_id = ?', whereArgs: [trackId]);
      _logger?.info('Deleted offline audio blob for $trackId', tag: 'OfflineAudioStorage');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final safeId = safeFilename(trackId);
      final file = File('${appDir.path}/downloads/$safeId.m4a');
      if (file.existsSync()) {
        try {
          await file.delete();
          _logger?.info('Deleted offline audio file at ${file.path}', tag: 'OfflineAudioStorage');
        } catch (e) {
          _logger?.warning('Failed to delete offline file: $e', tag: 'OfflineAudioStorage');
        }
      }
    }
  }

  /// Cleans up any remaining active object URLs.
  void dispose() {
    if (kIsWeb) {
      for (final url in _activeBlobUrls.values) {
        WebBlobUrlHelper.revokeBlobUrl(url);
      }
      _activeBlobUrls.clear();
    }
  }
}
