import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/onboarding/entry_gate.dart';

/// Root application widget mounting [EntryGate] and [ProviderScope].
class EchoBloomApp extends StatelessWidget {
  final ProviderContainer container;

  const EchoBloomApp({
    super.key,
    required this.container,
  });

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: const _AppView(),
    );
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 150),
      themeAnimationCurve: Curves.easeOutCubic,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryPurple,
          surface: AppColors.surface,
          onSurface: AppColors.textNavy,
          error: AppColors.errorRed,
        ),
        dividerColor: AppColors.divider,
        iconTheme: const IconThemeData(color: AppColors.iconNavy),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryPurple,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: AppColors.errorRed,
        ),
        dividerColor: AppColors.darkDivider,
        iconTheme: const IconThemeData(color: AppColors.darkIcon),
      ),
      home: const EntryGate(),
    );
  }
}

/// Backwards compatibility alias for the root app widget.
typedef SoundFoundryApp = EchoBloomApp;
