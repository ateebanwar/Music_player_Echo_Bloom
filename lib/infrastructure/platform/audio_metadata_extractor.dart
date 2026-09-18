import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Extracted audio metadata including embedded artwork path if found.
class ExtractedAudioMetadata {
  final String title;
  final String artist;
  final String album;
  final int? trackNumber;
  final int? year;
  final String? genre;
  final Duration duration;
  final String? artworkFilePath;

  const ExtractedAudioMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.trackNumber,
    this.year,
    this.genre,
    required this.duration,
    this.artworkFilePath,
  });
}

/// Lightweight, high-performance pure-Dart ID3v1/ID3v2 metadata & embedded artwork extractor.
abstract final class AudioMetadataExtractor {
  static Directory? _artworkCacheDir;

  static Future<Directory> _getArtworkCacheDir() async {
    if (_artworkCacheDir != null && await _artworkCacheDir!.exists()) {
      return _artworkCacheDir!;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDir.path, 'album_art_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _artworkCacheDir = cacheDir;
    return cacheDir;
  }

  /// Extracts metadata and embedded album artwork from a local audio file.
  static Future<ExtractedAudioMetadata> extractFromFile(File file) async {
    final fileName = p.basenameWithoutExtension(file.path);
    String title = fileName;
    String artist = 'Unknown Artist';
    String album = 'Unknown Album';
    int? trackNumber;
    int? year;
    String? genre;
    Duration duration = const Duration(minutes: 3, seconds: 30);
    String? artworkPath;

    try {
      final length = await file.length();
      if (length < 128) {
        return ExtractedAudioMetadata(
          title: title,
          artist: artist,
          album: album,
          duration: duration,
        );
      }

      final randomAccess = await file.open(mode: FileMode.read);
      try {
        // Read header for ID3v2
        final header = await randomAccess.read(10);
        if (header.length >= 10 &&
            header[0] == 0x49 && // 'I'
            header[1] == 0x44 && // 'D'
            header[2] == 0x33) {  // '3'
          final majorVersion = header[3];
          final tagSize = _decodeSyncSafe(header.sublist(6, 10));

          if (tagSize > 0 && tagSize <= 10 * 1024 * 1024) {
            final tagBytes = await randomAccess.read(tagSize);
            final parsed = await _parseId3v2(tagBytes, majorVersion, file.path);

            if (parsed.title != null && parsed.title!.isNotEmpty) title = parsed.title!;
            if (parsed.artist != null && parsed.artist!.isNotEmpty) artist = parsed.artist!;
            if (parsed.album != null && parsed.album!.isNotEmpty) album = parsed.album!;
            if (parsed.trackNumber != null) trackNumber = parsed.trackNumber;
            if (parsed.year != null) year = parsed.year;
            if (parsed.genre != null && parsed.genre!.isNotEmpty) genre = parsed.genre!;
            if (parsed.artworkPath != null) artworkPath = parsed.artworkPath;
          }
        } else {
          // Check ID3v1 at end of file
          await randomAccess.setPosition(length - 128);
          final id3v1Bytes = await randomAccess.read(128);
          if (id3v1Bytes.length == 128 &&
              id3v1Bytes[0] == 0x54 && // 'T'
              id3v1Bytes[1] == 0x41 && // 'A'
              id3v1Bytes[2] == 0x47) {  // 'G'
            final v1Title = _latin1String(id3v1Bytes.sublist(3, 33)).trim();
            final v1Artist = _latin1String(id3v1Bytes.sublist(33, 63)).trim();
            final v1Album = _latin1String(id3v1Bytes.sublist(63, 93)).trim();
            final v1YearStr = _latin1String(id3v1Bytes.sublist(93, 97)).trim();

            if (v1Title.isNotEmpty) title = v1Title;
            if (v1Artist.isNotEmpty) artist = v1Artist;
            if (v1Album.isNotEmpty) album = v1Album;
            if (v1YearStr.isNotEmpty) year = int.tryParse(v1YearStr);
          }
        }
      } finally {
        await randomAccess.close();
      }
    } catch (_) {
      // Graceful fallback to filename
    }

    return ExtractedAudioMetadata(
      title: title,
      artist: artist,
      album: album,
      trackNumber: trackNumber,
      year: year,
      genre: genre,
      duration: duration,
      artworkFilePath: artworkPath,
    );
  }

  static int _decodeSyncSafe(Uint8List bytes) {
    return (bytes[0] << 21) | (bytes[1] << 14) | (bytes[2] << 7) | bytes[3];
  }

  static String _latin1String(List<int> bytes) {
    final nullIdx = bytes.indexOf(0);
    final validBytes = nullIdx >= 0 ? bytes.sublist(0, nullIdx) : bytes;
    return latin1.decode(validBytes, allowInvalid: true);
  }

  static Future<_ParsedId3v2> _parseId3v2(
      Uint8List bytes, int majorVersion, String sourceFilePath) async {
    String? title;
    String? artist;
    String? album;
    int? trackNumber;
    int? year;
    String? genre;
    String? artworkPath;

    var offset = 0;
    while (offset + 10 < bytes.length) {
      if (bytes[offset] == 0) {
        offset++;
        continue;
      }

      String frameId;
      int frameSize;

      if (majorVersion == 2) {
        if (offset + 6 > bytes.length) break;
        frameId = latin1.decode(bytes.sublist(offset, offset + 3), allowInvalid: true);
        frameSize = (bytes[offset + 3] << 16) | (bytes[offset + 4] << 8) | bytes[offset + 5];
        offset += 6;
      } else {
        if (offset + 10 > bytes.length) break;
        frameId = latin1.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);
        if (majorVersion == 4) {
          frameSize = _decodeSyncSafe(bytes.sublist(offset + 4, offset + 8));
        } else {
          frameSize = (bytes[offset + 4] << 24) |
              (bytes[offset + 5] << 16) |
              (bytes[offset + 6] << 8) |
              bytes[offset + 7];
        }
        offset += 10;
      }

      if (frameSize <= 0 || offset + frameSize > bytes.length) {
        break;
      }

      final frameData = bytes.sublist(offset, offset + frameSize);
      offset += frameSize;

      if (frameId == 'TIT2' || frameId == 'TT2') {
        title = _decodeTextFrame(frameData);
      } else if (frameId == 'TPE1' || frameId == 'TP1') {
        artist = _decodeTextFrame(frameData);
      } else if (frameId == 'TALB' || frameId == 'TAL') {
        album = _decodeTextFrame(frameData);
      } else if (frameId == 'TRCK' || frameId == 'TRK') {
        final trackStr = _decodeTextFrame(frameData);
        final numPart = trackStr.split('/').first.trim();
        trackNumber = int.tryParse(numPart);
      } else if (frameId == 'TYER' || frameId == 'TDRC' || frameId == 'TYE') {
        final yearStr = _decodeTextFrame(frameData);
        final cleanYear = RegExp(r'\d{4}').firstMatch(yearStr)?.group(0);
        if (cleanYear != null) year = int.tryParse(cleanYear);
      } else if (frameId == 'TCON' || frameId == 'TCO') {
        genre = _decodeTextFrame(frameData);
      } else if (frameId == 'APIC' || frameId == 'PIC') {
        artworkPath ??= await _extractAndSaveArtwork(frameData, sourceFilePath);
      }
    }

    return _ParsedId3v2(
      title: title,
      artist: artist,
      album: album,
      trackNumber: trackNumber,
      year: year,
      genre: genre,
      artworkPath: artworkPath,
    );
  }

  static String _decodeTextFrame(Uint8List data) {
    if (data.isEmpty) return '';
    final encoding = data[0];
    final textBytes = data.sublist(1);

    try {
      if (encoding == 0) {
        return _latin1String(textBytes).trim();
      } else if (encoding == 1 || encoding == 2) {
        return utf8.decode(textBytes, allowMalformed: true).replaceAll('\x00', '').trim();
      } else if (encoding == 3) {
        return utf8.decode(textBytes, allowMalformed: true).replaceAll('\x00', '').trim();
      }
    } catch (_) {}
    return _latin1String(textBytes).trim();
  }

  static Future<String?> _extractAndSaveArtwork(
      Uint8List data, String sourceFilePath) async {
    try {
      if (data.length < 10) return null;

      // Find image start bytes (JPEG 0xFFD8 or PNG 0x89504E47)
      int imgStart = -1;
      for (var i = 0; i < data.length - 4; i++) {
        if (data[i] == 0xFF && data[i + 1] == 0xD8) {
          imgStart = i;
          break;
        }
        if (data[i] == 0x89 &&
            data[i + 1] == 0x50 &&
            data[i + 2] == 0x4E &&
            data[i + 3] == 0x47) {
          imgStart = i;
          break;
        }
      }

      if (imgStart >= 0) {
        final imageBytes = data.sublist(imgStart);
        if (imageBytes.isNotEmpty) {
          final cacheDir = await _getArtworkCacheDir();
          final fileNameHash = sourceFilePath.hashCode.abs().toString();
          final isPng = imageBytes[0] == 0x89;
          final ext = isPng ? '.png' : '.jpg';
          final targetFile = File(p.join(cacheDir.path, 'art_$fileNameHash$ext'));
          await targetFile.writeAsBytes(imageBytes, flush: true);
          return targetFile.path;
        }
      }
    } catch (_) {}
    return null;
  }
}

class _ParsedId3v2 {
  final String? title;
  final String? artist;
  final String? album;
  final int? trackNumber;
  final int? year;
  final String? genre;
  final String? artworkPath;

  const _ParsedId3v2({
    this.title,
    this.artist,
    this.album,
    this.trackNumber,
    this.year,
    this.genre,
    this.artworkPath,
  });
}
