import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sound_foundry/app/config/online_music_config.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Client for JioSaavn unofficial API.
/// Performs universal search, album lookups, and normalizes results into domain entities.
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

  /// Normalizes a query by trimming, stripping excessive spaces, and removing dangerous characters.
  static String normalizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Searches JioSaavn catalog for matching tracks with relevance ranking and deduplication.
  Future<List<Track>> search(String query) async {
    final trimmed = normalizeQuery(query);
    if (trimmed.isEmpty) return const [];

    final tracks = await _fetchSearchResults(trimmed);
    if (tracks.isNotEmpty) {
      return rankAndDeduplicate(tracks, trimmed);
    }

    // If query failed or returned empty and has punctuation or odd chars, try with sanitized alphanumeric
    final sanitized = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '').trim();
    if (sanitized.isNotEmpty && sanitized != trimmed) {
      final retryTracks = await _fetchSearchResults(sanitized);
      if (retryTracks.isNotEmpty) {
        return rankAndDeduplicate(retryTracks, sanitized);
      }
    }

    return const [];
  }

  Future<List<Track>> _fetchSearchResults(String queryStr) async {
    final uri = Uri.parse(
      '${JioSaavnConfig.baseUrl}${JioSaavnConfig.searchEndpoint}?query=${Uri.encodeComponent(queryStr)}',
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
        _logger?.warning('JioSaavn returned status: ${response.statusCode}', tag: 'JioSaavnClient');
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

  /// Fetches all tracks for an album using its permanent JioSaavn album URL or ID.
  Future<List<Track>> fetchAlbumTracks(String albumUrl) async {
    final trimmed = albumUrl.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(
      '${JioSaavnConfig.baseUrl}/album/?query=${Uri.encodeComponent(trimmed)}',
    );

    _logger?.info('Fetching album details from: $uri', tag: 'JioSaavnClient');

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
        if (decoded is Map<String, dynamic> && decoded['songs'] != null) {
          return parseTracks(decoded['songs']);
        }
        return parseTracks(decoded);
      }
    } catch (e, stack) {
      _logger?.warning('Failed to fetch album tracks: $e', tag: 'JioSaavnClient', error: e, stackTrace: stack);
    }
    return const [];
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
      } else if (json['result'] is List) {
        rawList = json['result'] as List<dynamic>;
      } else if (json['data'] is List) {
        rawList = json['data'] as List<dynamic>;
      } else if (json['songs'] is List) {
        rawList = json['songs'] as List<dynamic>;
      } else if (json['song'] != null || json['title'] != null || json['id'] != null) {
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

  /// Ranks tracks based on match strength to the query and removes duplicates.
  List<Track> rankAndDeduplicate(List<Track> tracks, String query) {
    final lowerQ = query.toLowerCase();
    final seen = <String>{};
    final uniqueTracks = <Track>[];

    for (final track in tracks) {
      final key = '${track.title.toLowerCase()}___${track.artist.toLowerCase()}';
      if (!seen.add(key) && !seen.add(track.id)) {
        continue;
      }
      uniqueTracks.add(track);
    }

    uniqueTracks.sort((a, b) {
      final scoreA = _computeRelevanceScore(a, lowerQ);
      final scoreB = _computeRelevanceScore(b, lowerQ);
      return scoreB.compareTo(scoreA); // Higher score first
    });

    return uniqueTracks;
  }

  int _computeRelevanceScore(Track track, String lowerQ) {
    final title = track.title.toLowerCase();
    final artist = track.artist.toLowerCase();
    final album = (track.album ?? '').toLowerCase();

    if (title == lowerQ) return 100;
    if (title.startsWith(lowerQ)) return 80;
    if (title.contains(lowerQ)) return 60;
    if (artist == lowerQ) return 50;
    if (artist.startsWith(lowerQ)) return 40;
    if (artist.contains(lowerQ)) return 30;
    if (album.contains(lowerQ)) return 20;
    return 10;
  }

  /// Extracts structured [Artist] models from retrieved tracks.
  List<Artist> extractArtists(List<Track> tracks) {
    final artistMap = <String, List<Track>>{};
    for (final track in tracks) {
      final rawArtists = track.artist.split(RegExp(r'[,&/]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
      for (final artist in rawArtists) {
        if (artist.toLowerCase() == 'unknown artist') continue;
        artistMap.putIfAbsent(artist, () => []).add(track);
      }
    }

    final artists = <Artist>[];
    artistMap.forEach((name, artistTracks) {
      final artwork = artistTracks.firstWhere((t) => t.artworkUri != null, orElse: () => artistTracks.first).artworkUri;
      final albumCount = artistTracks.map((t) => t.album).where((a) => a != null && a.isNotEmpty).toSet().length;
      artists.add(Artist(
        id: 'artist_${name.hashCode}',
        name: name,
        trackCount: artistTracks.length,
        albumCount: albumCount > 0 ? albumCount : 1,
        artworkUri: artwork,
      ));
    });

    artists.sort((a, b) => b.trackCount.compareTo(a.trackCount));
    return artists;
  }

  /// Extracts structured [Album] models from retrieved tracks.
  List<Album> extractAlbums(List<Track> tracks) {
    final albumMap = <String, List<Track>>{};
    for (final track in tracks) {
      final albumName = track.album?.trim();
      if (albumName == null || albumName.isEmpty) continue;
      albumMap.putIfAbsent(albumName, () => []).add(track);
    }

    final albums = <Album>[];
    albumMap.forEach((title, albumTracks) {
      final first = albumTracks.first;
      albums.add(Album(
        id: 'album_${title.hashCode}',
        title: title,
        artist: first.artist,
        year: first.year,
        trackCount: albumTracks.length,
        artworkUri: first.artworkUri,
      ));
    });

    albums.sort((a, b) => b.trackCount.compareTo(a.trackCount));
    return albums;
  }
}

