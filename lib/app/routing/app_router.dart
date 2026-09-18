import 'package:flutter/widgets.dart';

/// App route name identifiers.
abstract final class AppRoutes {
  static const String root = '/';
  static const String library = '/library';
  static const String player = '/player';
  static const String playlist = '/playlist';
  static const String settings = '/settings';
  static const String search = '/search';
}

/// Abstract contract for navigation.
/// Keeps navigation decoupled from widgets and framework specifics.
abstract class AppRouter {
  String get initialRoute;
  Route<dynamic>? onGenerateRoute(RouteSettings settings);
}

/// Headless/Placeholder router for foundational phase (zero UI screens).
class DefaultAppRouter implements AppRouter {
  @override
  String get initialRoute => AppRoutes.root;

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}
