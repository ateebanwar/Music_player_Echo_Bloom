import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sound_foundry/app/config/online_music_config.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/data/remote/clients/jiosaavn_client.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Fallback client for Gaana unofficial API.
/// Performs fallback search and stream resolution.
class GaanaClient {
  final http.Client _httpClient;
  final AppLogger? _logger;

  GaanaClient({
    http.Client? httpClient,
    AppLogger? logger,
  })  : _httpClient = httpClient ?? http.Client(),
        _logger = logger;

  /// Searches Gaana catalog for matching tracks.
  Future<List<Track>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(
      '${GaanaConfig.baseUrl}${GaanaConfig.searchEndpoint}?q=${Uri.encodeComponent(trimmed)}&type=song',
    );

    _logger?.info('Gaana fallback search requested: $uri', tag: 'GaanaClient');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/1.0 (Mobile; Flutter)',
        },
      ).timeout(GaanaConfig.timeout);

      if (response.statusCode != 200) {
        _logger?.warning('Gaana returned non-200 status: ${response.statusCode}', tag: 'GaanaClient');
        return const [];
      }

      final responseBody = response.body;
      if (responseBody.trim().isEmpty || responseBody.startsWith('<') || responseBody.contains('DEPLOYMENT_DISABLED')) {
        _logger?.warning('Gaana returned non-JSON or disabled response', tag: 'GaanaClient');
        return const [];
      }

      final decoded = jsonDecode(responseBody);
      return parseTracks(decoded);
    } catch (e, stack) {
      _logger?.warning('Gaana fallback search failed: $e', tag: 'GaanaClient', error: e, stackTrace: stack);
      return const [];
    }
  }

  /// Resolves the actual playable stream URL for a Gaana track by its seokey.
  Future<String> resolveStreamUri(String seokey) async {
    final cleanKey = seokey.replaceFirst('gaana://stream?seokey=', '').trim();
    if (cleanKey.isEmpty) return '';

    final uri = Uri.parse(
      '${GaanaConfig.baseUrl}${GaanaConfig.streamEndpoint}?seokey=${Uri.encodeComponent(cleanKey)}',
    );

    _logger?.info('Gaana stream resolution requested: $uri', tag: 'GaanaClient');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/1.0 (Mobile; Flutter)',
        },
      ).timeout(GaanaConfig.timeout);

      if (response.statusCode != 200) {
        _logger?.warning('Gaana stream resolution non-200: ${response.statusCode}', tag: 'GaanaClient');
        return '';
      }

      final responseBody = response.body;
      if (responseBody.trim().isEmpty || responseBody.startsWith('<')) {
        return '';
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final streamUrl = (decoded['link'] ??
                decoded['stream'] ??
                decoded['stream_url'] ??
                decoded['audio_url'] ??
                decoded['hls_url'] ??
                '')
            .toString()
            .trim();
        return streamUrl;
      }
      return '';
    } catch (e) {
      _logger?.warning('Gaana stream resolution failed: $e', tag: 'GaanaClient');
      return '';
    }
  }

  /// Safely parses raw JSON data into domain [Track] objects.
  List<Track> parseTracks(dynamic json) {
    final List<dynamic> rawList;
    if (json is List) {
      rawList = json;
    } else if (json is Map<String, dynamic>) {
      if (json['tracks'] is List) {
        rawList = json['tracks'] as List<dynamic>;
      } else if (json['data'] is List) {
        rawList = json['data'] as List<dynamic>;
      } else if (json['results'] is List) {
        rawList = json['results'] as List<dynamic>;
      } else {
        rawList = const [];
      }
    } else {
      rawList = const [];
    }

    final tracks = <Track>[];
    final now = DateTime.now();

    for (final item in rawList) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final seokey = (map['seokey']?.toString() ?? map['id']?.toString() ?? '').trim();
      final songTitle = JioSaavnClient.unescapeHtml(
        map['track_title']?.toString() ?? map['title']?.toString() ?? map['song']?.toString() ?? '',
      );
      if (seokey.isEmpty && songTitle.isEmpty) continue;

      String artist = JioSaavnClient.unescapeHtml(
        map['artist_name']?.toString() ??
            map['artist']?.toString() ??
            map['singers']?.toString() ??
            'Unknown Artist',
      );
      if (artist.isEmpty) artist = 'Unknown Artist';

      final rawAlbum = map['album_title']?.toString() ?? map['album']?.toString();
      final album = (rawAlbum != null && rawAlbum.isNotEmpty) ? JioSaavnClient.unescapeHtml(rawAlbum) : null;

      final rawDuration = map['duration']?.toString() ?? '';
      final durationSec = int.tryParse(rawDuration) ?? 0;
      final duration = Duration(seconds: durationSec);

      final rawImage = (map['artwork'] ?? map['image'] ?? map['artwork_large'] ?? '').toString().trim();
      final artworkUri = rawImage.isNotEmpty ? rawImage : null;

      final mediaUri = 'gaana://stream?seokey=$seokey';
      final trackId = seokey.isNotEmpty ? 'gaana_$seokey' : 'gaana_${songTitle.hashCode}';

      tracks.add(Track(
        id: trackId,
        title: songTitle.isNotEmpty ? songTitle : 'Unknown Title',
        artist: artist,
        album: album,
        duration: duration,
        mediaUri: mediaUri,
        sourceType: TrackSourceType.remoteStream,
        artworkUri: artworkUri,
        dateAdded: now,
        remoteProvider: 'gaana',
        remoteProviderId: seokey.isNotEmpty ? seokey : null,
      ));
    }

    return tracks;
  }
}
