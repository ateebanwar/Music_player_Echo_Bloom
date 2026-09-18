/// Centralized configuration for remote music streaming and search providers.
/// All URLs, endpoints, timeouts, and cache limits are declared here.
abstract final class JioSaavnConfig {
  /// Base URL of the deployed JioSaavn API.
  static const String baseUrl = 'https://saavnapi-nine.vercel.app';

  /// Universal search endpoint route: `/result/?query=<QUERY>`.
  static const String searchEndpoint = '/result/';

  /// Network timeout for API operations.
  static const Duration timeout = Duration(seconds: 8);
}

abstract final class GaanaConfig {
  /// Base URL of the deployed Gaana API.
  static const String baseUrl = 'https://shnwazdev-gaana-api.vercel.app';

  /// Search endpoint route: `/api/search?q=<QUERY>&type=song`.
  static const String searchEndpoint = '/api/search';

  /// Stream endpoint route: `/api/stream?seokey=<SEOKEY>`.
  static const String streamEndpoint = '/api/stream';

  /// Network timeout for fallback API operations.
  static const Duration timeout = Duration(seconds: 8);
}
