import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/features/profile/profile_controller.dart';
import 'package:sound_foundry/features/search/search_controller.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/about/about_screen.dart';
import 'package:sound_foundry/presentation/screens/downloaded/downloaded_screen.dart';
import 'package:sound_foundry/presentation/screens/equalizer/equalizer_screen.dart';
import 'package:sound_foundry/presentation/screens/main_navigation_shell.dart';
import 'package:sound_foundry/presentation/screens/profile/profile_screen.dart';
import 'package:sound_foundry/presentation/screens/settings/settings_screen.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/user_profile_avatar.dart';

/// Compact, premium navigation drawer displaying user profile, navigation items,
/// single operating mode toggle, appearance, About, and bottom-anchored settings.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final isDark = ref.watch(isDarkModeProvider);

    final profile = profileState.profile;
    final userName = profile?.name ?? 'Local User';
    final ageText = profile != null ? 'Age: ${profile.age} • ${profile.gender}' : 'Offline Sanctuary';

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      elevation: 16.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top: User Profile Header (Tappable to view/edit profile)
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                ProfileScreen.show(context);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 12.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    UserProfileAvatar(
                      avatarPath: profile?.avatarKey,
                      name: userName,
                      size: 44.0,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 15.0,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1.0),
                          Text(
                            ageText,
                            style: AppTypography.artistName.copyWith(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
                      size: 18.0,
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Middle Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                children: [
                  // Section Header: Navigation
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      'MUSIC PLAYER',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    minLeadingWidth: 28.0,
                    visualDensity: VisualDensity.compact,
                    leading: CustomIcons.musicNote(
                      size: 19.0,
                      color: isDark ? AppColors.darkText : AppColors.iconNavy,
                    ),
                    title: Text(
                      'Now Playing',
                      style: AppTypography.headerTitle.copyWith(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    onTap: () {
                      ref.read(mainNavIndexProvider.notifier).state = 0;
                      Navigator.of(context).pop();
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    minLeadingWidth: 28.0,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      Icons.library_music_rounded,
                      size: 19.0,
                      color: isDark ? AppColors.darkText : AppColors.iconNavy,
                    ),
                    title: Text(
                      'All Songs',
                      style: AppTypography.headerTitle.copyWith(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    onTap: () {
                      ref.read(mainNavIndexProvider.notifier).state = 1;
                      Navigator.of(context).pop();
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    minLeadingWidth: 28.0,
                    visualDensity: VisualDensity.compact,
                    leading: CustomIcons.playlistGrid(
                      size: 19.0,
                      color: isDark ? AppColors.darkText : AppColors.iconNavy,
                    ),
                    title: Text(
                      'Playlists',
                      style: AppTypography.headerTitle.copyWith(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    onTap: () {
                      ref.read(mainNavIndexProvider.notifier).state = 3;
                      Navigator.of(context).pop();
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    minLeadingWidth: 28.0,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(
                      Icons.download_done_rounded,
                      size: 19.0,
                      color: AppColors.primaryPurple,
                    ),
                    title: Text(
                      'Downloaded',
                      style: AppTypography.headerTitle.copyWith(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      DownloadedScreen.show(context);
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    minLeadingWidth: 28.0,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.equalizer_rounded, size: 19.0, color: AppColors.primaryPurple),
                    title: Text(
                      'Equalizer',
                      style: AppTypography.headerTitle.copyWith(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      EqualizerScreen.show(context);
                    },
                  ),

                  const SizedBox(height: 6.0),
                  Divider(color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface, height: 1.0),
                  const SizedBox(height: 6.0),

                  // Section Header: Operating Mode
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      'OPERATING MODE',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),

                  // Unified Single Mode Control Toggle
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        // Offline Mode Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (settingsState.appMode != AppMode.offline) {
                                settingsNotifier.setAppMode(AppMode.offline);
                                ref.read(searchFocusTriggerProvider.notifier).state = false;
                                ref.read(mainNavIndexProvider.notifier).state = 1;
                                Navigator.of(context).pop();
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: settingsState.appMode == AppMode.offline
                                    ? AppColors.primaryPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9.0),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_off_rounded,
                                        size: 16.0,
                                        color: settingsState.appMode == AppMode.offline
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextMuted : AppColors.iconNavy),
                                      ),
                                      const SizedBox(width: 6.0),
                                      Text(
                                        'Offline Mode',
                                        style: TextStyle(
                                          color: settingsState.appMode == AppMode.offline
                                              ? Colors.white
                                              : (isDark ? AppColors.darkText : AppColors.textNavy),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        // Online Mode Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (settingsState.appMode != AppMode.online) {
                                settingsNotifier.setAppMode(AppMode.online);
                                ref.read(searchFocusTriggerProvider.notifier).state = true;
                                ref.read(mainNavIndexProvider.notifier).state = 1;
                                Navigator.of(context).pop();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: settingsState.appMode == AppMode.online
                                    ? AppColors.primaryPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9.0),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_queue_rounded,
                                        size: 16.0,
                                        color: settingsState.appMode == AppMode.online
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextMuted : AppColors.iconNavy),
                                      ),
                                      const SizedBox(width: 6.0),
                                      Text(
                                        'Online Mode',
                                        style: TextStyle(
                                          color: settingsState.appMode == AppMode.online
                                              ? Colors.white
                                              : (isDark ? AppColors.darkText : AppColors.textNavy),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6.0),
                  Divider(color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface, height: 1.0),
                  const SizedBox(height: 6.0),

                  // Section Header: Appearance
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      'APPEARANCE',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => settingsNotifier.setThemeMode(ThemeMode.light),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: settingsState.themeMode == ThemeMode.light
                                  ? AppColors.primaryPurple
                                  : (isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface),
                              borderRadius: BorderRadius.circular(9.0),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.light_mode_rounded,
                                    size: 16.0,
                                    color: settingsState.themeMode == ThemeMode.light
                                        ? Colors.white
                                        : (isDark ? AppColors.darkText : AppColors.iconNavy),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'Light',
                                    style: TextStyle(
                                      color: settingsState.themeMode == ThemeMode.light
                                          ? Colors.white
                                          : (isDark ? AppColors.darkText : AppColors.textNavy),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => settingsNotifier.setThemeMode(ThemeMode.dark),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: settingsState.themeMode == ThemeMode.dark
                                  ? AppColors.primaryPurple
                                  : (isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface),
                              borderRadius: BorderRadius.circular(9.0),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.dark_mode_rounded,
                                    size: 16.0,
                                    color: settingsState.themeMode == ThemeMode.dark
                                        ? Colors.white
                                        : (isDark ? AppColors.darkText : AppColors.iconNavy),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'Dark',
                                    style: TextStyle(
                                      color: settingsState.themeMode == ThemeMode.dark
                                          ? Colors.white
                                          : (isDark ? AppColors.darkText : AppColors.textNavy),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6.0),
                  Divider(color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface, height: 1.0),
                  const SizedBox(height: 4.0),

                  // About Navigation Item
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    minLeadingWidth: 28.0,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.info_outline_rounded, size: 19.0, color: AppColors.primaryPurple),
                    title: Text(
                      'About ${AppConstants.appName}',
                      style: AppTypography.headerTitle.copyWith(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      AboutScreen.show(context);
                    },
                  ),
                ],
              ),
            ),

            // Developer Attribution
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Text(
                AppConstants.developerAttribution,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),

            // Strictly Bottom-Anchored Settings Section
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 10.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                    width: 1.0,
                  ),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.settings_rounded,
                  size: 20.0,
                  color: isDark ? AppColors.darkText : AppColors.iconNavy,
                ),
                title: Text(
                  'Settings',
                  style: AppTypography.headerTitle.copyWith(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                  ),
                ),
                subtitle: Text(
                  'Preferences & App Info',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 18.0,
                  color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  SettingsScreen.show(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
