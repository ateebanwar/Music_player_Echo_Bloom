import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/data/remote/clients/gaana_client.dart';
import 'package:sound_foundry/data/remote/clients/jiosaavn_client.dart';
import 'package:sound_foundry/data/remote/contracts/remote_music_data_source.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';

import 'package:sound_foundry/data/remote/providers/gaana_provider.dart';
import 'package:sound_foundry/data/remote/providers/remote_music_provider.dart';

/// Concrete implementation of [RemoteMusicDataSource].
/// Coordinates JioSaavn as the primary music provider and Gaana as the fallback provider.
class RemoteMusicDataSourceImpl implements RemoteMusicDataSource {
  final JioSaavnClient _jioSaavnClient;
  final RemoteMusicProvider _gaanaProvider;
  final AppLogger? _logger;

  // In-memory cache for recent searches (query -> tracks) to avoid duplicate network roundtrips
  final Map<String, List<Track>> _searchCache = {};
  static const int _maxCacheSize = 35;

  RemoteMusicDataSourceImpl({
    JioSaavnClient? jioSaavnClient,
    GaanaClient? gaanaClient,
    RemoteMusicProvider? gaanaProvider,
    AppLogger? logger,
  })  : _jioSaavnClient = jioSaavnClient ?? JioSaavnClient(logger: logger),
        _gaanaProvider = gaanaProvider ??
            GaanaProvider(client: gaanaClient ?? GaanaClient(logger: logger)),
        _logger = logger;

  @override
  Future<List<Track>> searchRemoteCatalog(String query) async {
    final trimmed = JioSaavnClient.normalizeQuery(query);
    if (trimmed.isEmpty) return const [];

    final cacheKey = trimmed.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      _logger?.info('Returning cached remote search for: "$trimmed"', tag: 'RemoteMusicDataSource');
      return _searchCache[cacheKey]!;
    }

    _logger?.info('Executing primary search with JioSaavn for: "$trimmed"', tag: 'RemoteMusicDataSource');

    // 1. Primary Provider: JioSaavn
    List<Track> results = const [];
    try {
      results = await _jioSaavnClient.search(trimmed);
    } catch (e, stack) {
      _logger?.warning('JioSaavn search exception: $e', tag: 'RemoteMusicDataSource', error: e, stackTrace: stack);
    }

    // 2. Fallback Provider: Gaana if JioSaavn returned no results
    if (results.isEmpty) {
      _logger?.info('JioSaavn returned no usable results. Attempting Gaana fallback for: "$trimmed"', tag: 'RemoteMusicDataSource');
      try {
        results = await _gaanaProvider.search(trimmed);
      } catch (e, stack) {
        _logger?.warning('Gaana fallback search exception: $e', tag: 'RemoteMusicDataSource', error: e, stackTrace: stack);
      }
    }

    // Cache successful results
    if (results.isNotEmpty) {
      if (_searchCache.length >= _maxCacheSize) {
        _searchCache.remove(_searchCache.keys.first);
      }
      _searchCache[cacheKey] = results;
    }

    return results;
  }

  @override
  Future<List<Artist>> fetchArtists([String? query]) async {
    final effectiveQuery = (query != null && query.trim().isNotEmpty)
        ? query.trim()
        : 'arijit singh';

    final tracks = await searchRemoteCatalog(effectiveQuery);
    return _jioSaavnClient.extractArtists(tracks);
  }

  @override
  Future<List<Album>> fetchAlbums([String? query]) async {
    final effectiveQuery = (query != null && query.trim().isNotEmpty)
        ? query.trim()
        : '1990 hindi hits';

    final tracks = await searchRemoteCatalog(effectiveQuery);
    return _jioSaavnClient.extractAlbums(tracks);
  }

  @override
  Future<List<Track>> fetchAlbumTracks(String albumUrlOrId) async {
    if (albumUrlOrId.startsWith('http://') || albumUrlOrId.startsWith('https://')) {
      return await _jioSaavnClient.fetchAlbumTracks(albumUrlOrId);
    }
    // Search as query fallback
    return await searchRemoteCatalog(albumUrlOrId);
  }

  @override
  Future<List<Playlist>> fetchDiscoveryPlaylists() async {
    final now = DateTime.now();
    return [
      Playlist(
        id: 'discovery_1990s_hindi',
        name: '1990s Hindi Hits',
        description: 'Timeless classic chartbusters from the golden 1990s era of Bollywood',
        trackCount: 20,
        artworkUri: 'https://c.saavncdn.com/588/Dilwale-Dulhania-Le-Jayenge-Hindi-1995-20171114-500x500.jpg',
        createdAt: now,
        updatedAt: now,
        isSmartPlaylist: true,
      ),
      Playlist(
        id: 'discovery_romantic_hits',
        name: 'Bollywood Romantic Hits',
        description: 'Heartwarming romantic anthems and soul-stirring melodies',
        trackCount: 20,
        artworkUri: 'https://c.saavncdn.com/430/Aashiqui-2-Hindi-2013-500x500.jpg',
        createdAt: now,
        updatedAt: now,
        isSmartPlaylist: true,
      ),
      Playlist(
        id: 'discovery_arijit_singh',
        name: 'Arijit Singh Essentials',
        description: 'The definitive collection of heartfelt songs by Arijit Singh',
        trackCount: 20,
        artworkUri: 'https://c.saavncdn.com/840/Best-Of-Arijit-Singh-Collection-Of-Romantic-Songs-Hindi-2025-20251203161112-500x500.jpg',
        createdAt: now,
        updatedAt: now,
        isSmartPlaylist: true,
      ),
      Playlist(
        id: 'discovery_90s_evergreen',
        name: '90s Evergreen Melodies',
        description: 'Kumar Sanu, Alka Yagnik, Udit Narayan & Kavita Krishnamurthy',
        trackCount: 20,
        artworkUri: 'https://c.saavncdn.com/410/Dil-To-Pagal-Hai-Hindi-1997-20190329145756-500x500.jpg',
        createdAt: now,
        updatedAt: now,
        isSmartPlaylist: true,
      ),
      Playlist(
        id: 'discovery_english_classics',
        name: 'English Pop Classics',
        description: 'World-class pop masterpieces, acoustic hits, and chart toppers',
        trackCount: 20,
        artworkUri: 'https://c.saavncdn.com/179/World-Music-Day-Best-Of-Bollywood-Hits-Hindi-2026-20260622111029-500x500.jpg',
        createdAt: now,
        updatedAt: now,
        isSmartPlaylist: true,
      ),
    ];
  }

  @override
  Future<List<Track>> fetchPlaylistTracks(String playlistIdOrQuery) async {
    final queryMap = {
      'discovery_1990s_hindi': '1990 hindi hits',
      'discovery_romantic_hits': 'bollywood romantic songs',
      'discovery_arijit_singh': 'arijit singh romantic',
      'discovery_90s_evergreen': '90s evergreen hindi songs',
      'discovery_english_classics': 'english pop hits',
    };

    final query = queryMap[playlistIdOrQuery] ?? playlistIdOrQuery;
    return await searchRemoteCatalog(query);
  }

  @override
  Future<String> resolveStreamUri(String trackIdOrUri, [Track? track]) async {
    if (trackIdOrUri.startsWith('http://') || trackIdOrUri.startsWith('https://')) {
      return trackIdOrUri;
    }

    final provider = track?.remoteProvider;

    // 1. Primary: JioSaavn resolution
    if (provider == 'jiosaavn' ||
        trackIdOrUri.startsWith('jiosaavn_') ||
        trackIdOrUri.startsWith('jiosaavn://')) {
      try {
        final jioUrl = await _jioSaavnClient.resolveStreamUri(
          trackIdOrUri,
          permaUrl: track?.remotePermaUrl,
          title: track?.title,
          artist: track?.artist,
        );
        if (jioUrl.isNotEmpty && (jioUrl.startsWith('http://') || jioUrl.startsWith('https://'))) {
          return jioUrl;
        }
      } catch (e) {
        _logger?.warning('JioSaavn stream resolution failed: $e, attempting Gaana fallback', tag: 'RemoteMusicDataSource');
      }

      // Gaana Fallback for failed JioSaavn stream
      try {
        final gaanaUrl = await _gaanaProvider.resolveStreamUri(
          track: track,
          trackIdOrQuery: trackIdOrUri,
        );
        if (gaanaUrl.isNotEmpty && (gaanaUrl.startsWith('http://') || gaanaUrl.startsWith('https://'))) {
          return gaanaUrl;
        }
      } catch (e) {
        _logger?.warning('Gaana fallback for JioSaavn stream failed: $e', tag: 'RemoteMusicDataSource');
      }
    }

    // 2. Gaana direct resolution
    if (provider == 'gaana' ||
        trackIdOrUri.startsWith('gaana://') ||
        trackIdOrUri.startsWith('gaana_')) {
      try {
        final streamUrl = await _gaanaProvider.resolveStreamUri(
          track: track,
          trackIdOrQuery: trackIdOrUri,
        );
        if (streamUrl.isNotEmpty && (streamUrl.startsWith('http://') || streamUrl.startsWith('https://'))) {
          return streamUrl;
        }
      } catch (e) {
        _logger?.warning('Gaana stream resolution failed: $e, trying JioSaavn fallback', tag: 'RemoteMusicDataSource');
      }

      // JioSaavn Fallback for failed Gaana stream
      try {
        final jioUrl = await _jioSaavnClient.resolveStreamUri(
          trackIdOrUri,
          permaUrl: track?.remotePermaUrl,
          title: track?.title,
          artist: track?.artist,
        );
        if (jioUrl.isNotEmpty && (jioUrl.startsWith('http://') || jioUrl.startsWith('https://'))) {
          return jioUrl;
        }
      } catch (_) {}
    }

    // 3. General fallback if provider is unspecified
    try {
      final jioUrl = await _jioSaavnClient.resolveStreamUri(
        trackIdOrUri,
        permaUrl: track?.remotePermaUrl,
        title: track?.title,
        artist: track?.artist,
      );
      if (jioUrl.isNotEmpty) return jioUrl;

      final gaanaUrl = await _gaanaProvider.resolveStreamUri(
        track: track,
        trackIdOrQuery: trackIdOrUri,
      );
      if (gaanaUrl.isNotEmpty) return gaanaUrl;
    } catch (_) {}

    return '';
  }

  @override
  Future<Track?> fetchTrackById(String id) async {
    for (final list in _searchCache.values) {
      for (final track in list) {
        if (track.id == id) return track;
      }
    }
    return null;
  }

  @override
  Future<PaginatedList<Track>> fetchTracks(PageQuery query) async {
    return const PaginatedList.empty();
  }
}

