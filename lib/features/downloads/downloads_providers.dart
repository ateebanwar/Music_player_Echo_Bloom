import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/features/downloads/downloads_contract.dart';

/// Provider for offline download management subsystem.
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DefaultDownloadManager();
});
