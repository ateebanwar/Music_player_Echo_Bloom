import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Permission status outcomes.
enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

/// Abstract contract for media and storage permission checks and requests.
/// Decouples permission handling from specific plugins or platform channels.
abstract class PermissionService {
  /// Checks whether media/audio read permission is currently granted.
  Future<PermissionState> checkAudioPermission();

  /// Requests media/audio read permission from the user.
  Future<PermissionState> requestAudioPermission();

  /// Opens application system settings if permanently denied.
  Future<bool> openAppSettings();
}

/// Robust platform-aware permission service implementation using [permission_handler].
class DefaultPermissionService implements PermissionService {
  PermissionState _mapStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
        return PermissionState.granted;
      case ph.PermissionStatus.denied:
        return PermissionState.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionState.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionState.restricted;
      default:
        return PermissionState.denied;
    }
  }

  @override
  Future<PermissionState> checkAudioPermission() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return PermissionState.granted;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // On modern Android (13+ / API 33+), Permission.audio is the canonical permission
        final audioStatus = await ph.Permission.audio.status;
        if (audioStatus.isGranted || audioStatus.isLimited) {
          return PermissionState.granted;
        }

        // On Android 12 and below, Permission.storage is used
        final storageStatus = await ph.Permission.storage.status;
        if (storageStatus.isGranted || storageStatus.isLimited) {
          return PermissionState.granted;
        }

        // If audio status is permanently denied or denied, prioritize audio status
        if (audioStatus.isPermanentlyDenied) {
          return PermissionState.permanentlyDenied;
        }
        if (audioStatus.isDenied) {
          return PermissionState.denied;
        }

        return _mapStatus(storageStatus);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final mediaLibraryStatus = await ph.Permission.mediaLibrary.status;
        return _mapStatus(mediaLibraryStatus);
      }

      return PermissionState.granted;
    } catch (_) {
      return PermissionState.granted;
    }
  }

  @override
  Future<PermissionState> requestAudioPermission() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return PermissionState.granted;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // First try requesting modern Android 13+ audio permission
        final audioStatus = await ph.Permission.audio.request();
        if (audioStatus.isGranted || audioStatus.isLimited) {
          return PermissionState.granted;
        }

        // If audio is permanently denied or not granted, check if legacy storage permission is needed/granted (for Android 12 and below)
        final storageStatus = await ph.Permission.storage.request();
        if (storageStatus.isGranted || storageStatus.isLimited) {
          return PermissionState.granted;
        }

        if (audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
          return PermissionState.permanentlyDenied;
        }

        return PermissionState.denied;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await ph.Permission.mediaLibrary.request();
        return _mapStatus(status);
      }

      return PermissionState.granted;
    } catch (_) {
      return PermissionState.granted;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }
    try {
      return await ph.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
