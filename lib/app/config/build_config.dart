/// Build environment mode.
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Immutable build configuration metadata.
class BuildConfig {
  final AppEnvironment environment;
  final String appName;
  final String packageName;
  final String version;
  final int buildNumber;
  final bool enableVerboseLogging;

  const BuildConfig({
    required this.environment,
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.enableVerboseLogging = false,
  });

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
}
