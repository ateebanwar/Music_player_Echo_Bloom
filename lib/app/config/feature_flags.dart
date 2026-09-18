import 'package:equatable/equatable.dart';

/// Centralized feature flags for controlled activation of features
/// without breaking foundational architecture.
class FeatureFlags extends Equatable {
  final bool enableRemoteSearch;
  final bool enableLyrics;
  final bool enableCloudSync;
  final bool enableDownloads;
  final bool enableRecommendations;

  const FeatureFlags({
    this.enableRemoteSearch = true,
    this.enableLyrics = true,
    this.enableCloudSync = false,
    this.enableDownloads = false,
    this.enableRecommendations = false,
  });

  FeatureFlags copyWith({
    bool? enableRemoteSearch,
    bool? enableLyrics,
    bool? enableCloudSync,
    bool? enableDownloads,
    bool? enableRecommendations,
  }) {
    return FeatureFlags(
      enableRemoteSearch: enableRemoteSearch ?? this.enableRemoteSearch,
      enableLyrics: enableLyrics ?? this.enableLyrics,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      enableDownloads: enableDownloads ?? this.enableDownloads,
      enableRecommendations: enableRecommendations ?? this.enableRecommendations,
    );
  }

  @override
  List<Object?> get props => [
        enableRemoteSearch,
        enableLyrics,
        enableCloudSync,
        enableDownloads,
        enableRecommendations,
      ];
}
