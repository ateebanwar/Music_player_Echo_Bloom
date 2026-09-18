import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sound_foundry/app/config/online_music_config.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Client for JioSaavn unofficial API.
/// Performs universal search and normalizes results into domain [Track] entities.
class JioSaavnClient {
  final http.Client _httpClient;
  final AppLogger? _logger;

  JioSaavnClient({
    http.Client? httpClient,
    AppLogger? logger,
  })  : _httpClient = httpClient ?? http.Client(),
        _logger = logger;

  /// Unescapes common HTML entities returned in API string fields.
  static String unescapeHtml(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Searches JioSaavn catalog for matching tracks.
  Future<List<Track>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(
      '${JioSaavnConfig.baseUrl}${JioSaavnConfig.searchEndpoint}?query=${Uri.encodeComponent(trimmed)}',
    );

    _logger?.info('JioSaavn search requested: $uri', tag: 'JioSaavnClient');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/1.0 (Mobile; Flutter)',
        },
      ).timeout(JioSaavnConfig.timeout);

      if (response.statusCode != 200) {
        _logger?.warning('JioSaavn returned non-200 status: ${response.statusCode}', tag: 'JioSaavnClient');
        return const [];
      }

      final responseBody = response.body;
      if (responseBody.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(responseBody);
      return parseTracks(decoded);
    } catch (e, stack) {
      _logger?.warning('JioSaavn search failed: $e', tag: 'JioSaavnClient', error: e, stackTrace: stack);
      return const [];
    }
  }

  /// Resolves the actual playable stream URL for a JioSaavn track by its ID, query, or permaUrl.
  Future<String> resolveStreamUri(
    String trackIdOrQuery, {
    String? permaUrl,
    String? title,
    String? artist,
  }) async {
    final clean = trackIdOrQuery.replaceFirst('jiosaavn_', '').trim();

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // 1. Try perma_url direct resolution if available
    final targetUrl = (permaUrl != null && permaUrl.isNotEmpty)
        ? permaUrl
        : (clean.startsWith('https://www.jiosaavn.com/song/') ? clean : null);

    if (targetUrl != null) {
      final track = await fetchSongByPermaUrl(targetUrl);
      if (track != null &&
          track.mediaUri.isNotEmpty &&
          (track.mediaUri.startsWith('http://') || track.mediaUri.startsWith('https://'))) {
        return track.mediaUri;
      }
    }

    // 2. Search using title and artist or query
    final queryStr = (title != null && title.isNotEmpty)
        ? (artist != null && artist.isNotEmpty ? '$title $artist' : title)
        : clean;

    if (queryStr.isEmpty) return '';

    _logger?.info('JioSaavn stream resolution requested for: $queryStr', tag: 'JioSaavnClient');
    final tracks = await search(queryStr);
    if (tracks.isNotEmpty) {
      for (final track in tracks) {
        if (track.mediaUri.isNotEmpty &&
            (track.mediaUri.startsWith('http://') || track.mediaUri.startsWith('https://'))) {
          return track.mediaUri;
        }
      }
    }
    return '';
  }

  /// Fetches a specific song's fresh details directly using its permanent JioSaavn URL.
  Future<Track?> fetchSongByPermaUrl(String permaUrl) async {
    final trimmed = permaUrl.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse(
      '${JioSaavnConfig.baseUrl}/song/?query=${Uri.encodeComponent(trimmed)}',
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/1.0 (Mobile; Flutter)',
        },
      ).timeout(JioSaavnConfig.timeout);

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        final list = parseTracks(decoded);
        if (list.isNotEmpty) return list.first;
      }
    } catch (e) {
      _logger?.warning('Failed to fetch song by permaUrl: $e', tag: 'JioSaavnClient');
    }
    return null;
  }

  /// Safely parses raw JSON data into domain [Track] objects.
  List<Track> parseTracks(dynamic json) {
    final List<dynamic> rawList;
    if (json is List) {
      rawList = json;
    } else if (json is Map<String, dynamic>) {
      if (json['results'] is List) {
        rawList = json['results'] as List<dynamic>;
      } else if (json['data'] is List) {
        rawList = json['data'] as List<dynamic>;
      } else if (json['song'] != null || json['title'] != null || json['id'] != null) {
        // Single song JSON response
        rawList = [json];
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

      final id = (map['id']?.toString() ?? '').trim();
      final songTitle = unescapeHtml(map['song']?.toString() ?? map['title']?.toString() ?? '');
      if (id.isEmpty && songTitle.isEmpty) continue;

      // Extract artists
      String artist = unescapeHtml(
        map['primary_artists']?.toString() ??
        map['singers']?.toString() ??
        map['artist']?.toString() ??
        map['music']?.toString() ??
        'Unknown Artist',
      );
      if (artist.isEmpty) artist = 'Unknown Artist';

      // Extract album
      final rawAlbum = map['album']?.toString();
      final album = (rawAlbum != null && rawAlbum.isNotEmpty) ? unescapeHtml(rawAlbum) : null;

      // Extract duration (in seconds)
      final rawDuration = map['duration']?.toString() ?? '';
      final durationSec = int.tryParse(rawDuration) ?? 0;
      final duration = Duration(seconds: durationSec);

      // Extract stream URL: prefer media_url, fallback to media_preview_url
      final mediaUrl = (map['media_url']?.toString() ?? '').trim();
      final previewUrl = (map['media_preview_url']?.toString() ?? '').trim();
      final streamUrl = mediaUrl.isNotEmpty ? mediaUrl : previewUrl;

      // Extract artwork image URL
      final rawImage = (map['image']?.toString() ?? '').trim();
      final artworkUri = rawImage.isNotEmpty ? rawImage : null;

      // Extract year & language
      final year = int.tryParse(map['year']?.toString() ?? '');
      final genre = map['language']?.toString();

      final permaUrl = (map['perma_url']?.toString() ?? '').trim();
      final remotePerma = permaUrl.isNotEmpty ? permaUrl : null;
      final remoteId = id.isNotEmpty ? id : null;

      final trackId = id.isNotEmpty ? 'jiosaavn_$id' : 'jiosaavn_${songTitle.hashCode}';
      final finalMediaUri = streamUrl.isNotEmpty
          ? streamUrl
          : (remotePerma != null && remotePerma.isNotEmpty
              ? remotePerma
              : 'jiosaavn://track/$trackId');

      tracks.add(Track(
        id: trackId,
        title: songTitle.isNotEmpty ? songTitle : 'Unknown Title',
        artist: artist,
        album: album,
        duration: duration,
        mediaUri: finalMediaUri,
        sourceType: TrackSourceType.remoteStream,
        artworkUri: artworkUri,
        year: year,
        genre: genre,
        dateAdded: now,
        remoteProvider: 'jiosaavn',
        remoteProviderId: remoteId,
        remotePermaUrl: remotePerma,
      ));
    }

    return tracks;
  }
}
