import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sound_foundry/app/config/app_config.dart';

/// Bootstraps Flutter engine bindings and environment configuration.
abstract final class EnvironmentBootstrap {
  static Future<AppConfig> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kReleaseMode) {
      return AppConfig.production();
    } else {
      return AppConfig.development();
    }
  }
}
