/// Represents the offline-first application operating mode.
enum AppMode {
  offline,
  online,
}

extension AppModeExtension on AppMode {
  String get displayName {
    switch (this) {
      case AppMode.offline:
        return 'Offline Mode';
      case AppMode.online:
        return 'Online Mode';
    }
  }

  String get description {
    switch (this) {
      case AppMode.offline:
        return 'Pure local playback & search with 0 network operations';
      case AppMode.online:
        return 'Permits future streaming & online metadata';
    }
  }
}
