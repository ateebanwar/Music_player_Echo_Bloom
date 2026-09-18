import 'package:equatable/equatable.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/track.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  canceled,
}

class DownloadTask extends Equatable {
  final String trackId;
  final DownloadStatus status;
  final double progress;
  final String? targetPath;

  const DownloadTask({
    required this.trackId,
    required this.status,
    this.progress = 0.0,
    this.targetPath,
  });

  @override
  List<Object?> get props => [trackId, status, progress, targetPath];
}

/// Abstract contract for offline track download manager.
abstract class DownloadManager {
  Stream<DownloadTask> get downloadStream;
  Future<Result<void, Failure>> enqueueDownload(Track track);
  Future<Result<void, Failure>> cancelDownload(String trackId);
  Future<Result<void, Failure>> removeDownloadedTrack(String trackId);
}

/// Headless/Default implementation of [DownloadManager].
class DefaultDownloadManager implements DownloadManager {
  @override
  Stream<DownloadTask> get downloadStream => const Stream.empty();

  @override
  Future<Result<void, Failure>> enqueueDownload(Track track) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> cancelDownload(String trackId) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> removeDownloadedTrack(String trackId) async {
    return const Result.ok(null);
  }
}
