import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/library/library_providers.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/search/search_controller.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// All Songs list screen supporting live Android MediaStore discovery, instant search, and context actions.
class AllSongsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const AllSongsScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends ConsumerState<AllSongsScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() => ref.read(libraryControllerProvider.notifier).loadLibrary());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(searchFocusTriggerProvider)) {
        ref.read(searchFocusTriggerProvider.notifier).state = false;
        if (_searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(searchFocusTriggerProvider, (previous, shouldFocus) {
      if (shouldFocus) {
        ref.read(searchFocusTriggerProvider.notifier).state = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _searchFocusNode.canRequestFocus) {
            _searchFocusNode.requestFocus();
          }
        });
      }
    });

    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (previous?.appMode != next.appMode && next.appMode == AppMode.offline) {
        _searchFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });

    final libraryState = ref.watch(libraryControllerProvider);
    final searchState = ref.watch(searchControllerProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final settings = ref.watch(settingsControllerProvider);
    final isOnline = settings.appMode == AppMode.online;

    final allLibraryTracks = libraryState.tracks.items;
    final isSearching = searchState.query.isNotEmpty;
    final displayedTracks = isSearching
        ? (isOnline ? searchState.remoteResults : searchState.localResults)
        : allLibraryTracks;

    final currentTrack = ref.watch(currentTrackProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final favoritesController = ref.read(favoritesControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header with Universal Hamburger Menu
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 10.0, 20.0, 8.0),
              child: Row(
                children: [
                  Semantics(
                    label: 'Menu',
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: widget.onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CustomIcons.menu(
                          size: 22.0,
                          color: isDark ? AppColors.darkIcon : AppColors.iconNavy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'All Songs',
                      style: AppTypography.trackTitle.copyWith(
                        fontSize: 22.0,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${displayedTracks.length} Track${displayedTracks.length == 1 ? '' : 's'}',
                        style: AppTypography.artistName.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 20.0,
                          color: isDark ? AppColors.darkTextMuted : AppColors.iconNavy,
                        ),
                        tooltip: 'Rescan Device Music',
                        onPressed: () {
                          ref.read(libraryControllerProvider.notifier).rescanLibrary();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar at Top of All Songs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                    fontSize: 14.0,
                  ),
                  decoration: InputDecoration(
                    hintText: isOnline
                        ? 'Search online music (JioSaavn / Gaana)...'
                        : 'Search songs, artists, albums...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      fontSize: 14.0,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20.0,
                      color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18.0,
                              color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchControllerProvider.notifier).clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  onChanged: (val) {
                    ref.read(searchControllerProvider.notifier).search(val);
                    setState(() {});
                  },
                ),
              ),
            ),

            // Track List / Search Results / Empty State / Loading State
            Expanded(
              child: _buildBody(
                context: context,
                isDark: isDark,
                isLoading: libraryState.isLoading,
                isSearching: isSearching,
                isSearchingInProgress: searchState.isSearching,
                searchStatusMessage: searchState.statusMessage,
                errorMessage: searchState.errorMessage,
                searchQuery: searchState.query,
                displayedTracks: displayedTracks,
                currentTrack: currentTrack,
                favorites: favoritesState.favorites,
                onToggleFavorite: (t) => favoritesController.toggleFavorite(t),
                onPlayTrack: (index) => playbackRepo.setQueue(displayedTracks, initialIndex: index),
                onRescan: () => ref.read(libraryControllerProvider.notifier).rescanLibrary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required bool isDark,
    required bool isLoading,
    required bool isSearching,
    required bool isSearchingInProgress,
    required String? searchStatusMessage,
    required String? errorMessage,
    required String searchQuery,
    required List<Track> displayedTracks,
    required Track? currentTrack,
    required List<Track> favorites,
    required void Function(Track) onToggleFavorite,
    required void Function(int) onPlayTrack,
    required VoidCallback onRescan,
  }) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryPurple,
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Scanning device for music...',
              style: AppTypography.artistName.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (isSearchingInProgress && displayedTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryPurple,
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              searchStatusMessage ?? 'Searching music...',
              style: AppTypography.artistName.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (isSearching && errorMessage != null && displayedTracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48.0,
                color: isDark
                    ? AppColors.darkTextMuted.withValues(alpha: 0.6)
                    : AppColors.iconMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Online Search Unavailable',
                style: AppTypography.headerTitle.copyWith(
                  fontSize: 16.0,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: AppTypography.artistName.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isSearching && displayedTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48.0,
              color: isDark
                  ? AppColors.darkTextMuted.withValues(alpha: 0.5)
                  : AppColors.iconMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12.0),
            Text(
              'No Songs Found',
              style: AppTypography.headerTitle.copyWith(
                fontSize: 16.0,
                color: isDark ? AppColors.darkText : AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'No matches for "$searchQuery"',
              style: AppTypography.artistName.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (displayedTracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 56.0,
                color: isDark
                    ? AppColors.darkTextMuted.withValues(alpha: 0.6)
                    : AppColors.iconMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16.0),
              Text(
                'No Local Songs Found',
                style: AppTypography.trackTitle.copyWith(
                  fontSize: 18.0,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Add audio files to your device or grant media storage permissions to discover your offline music library.',
                textAlign: TextAlign.center,
                style: AppTypography.artistName.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24.0),
              GestureDetector(
                onTap: onRescan,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  decoration: NeumorphicDecorations.elevatedCard(
                    borderRadius: BorderRadius.circular(24.0),
                    isDark: isDark,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 18.0,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Scan Device for Music',
                        style: AppTypography.headerTitle.copyWith(
                          color: AppColors.primaryPurple,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 24.0),
      itemCount: displayedTracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final track = displayedTracks[index];
        final isCurrent = currentTrack?.id == track.id;
        final isFavorite = favorites.any((f) => f.id == track.id);

        return Container(
          decoration: NeumorphicDecorations.elevatedCard(
            borderRadius: AppSpacing.roundedArtwork,
            isDark: isDark,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            leading: TrackArtworkWidget(
              artworkUri: track.artworkUri,
              size: 46.0,
              borderRadius: 12.0,
            ),
            title: Text(
              track.title,
              style: AppTypography.headerTitle.copyWith(
                fontSize: 15.0,
                color: isCurrent
                    ? AppColors.primaryPurple
                    : (isDark ? AppColors.darkText : AppColors.iconNavy),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist,
              style: AppTypography.artistName.copyWith(
                fontSize: 13.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Independent Heart Button
                GestureDetector(
                  onTap: () => onToggleFavorite(track),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomIcons.heart(
                      size: 20.0,
                      color: isFavorite
                          ? AppColors.favoriteRed
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.iconNavy.withValues(alpha: 0.4)),
                      isFilled: isFavorite,
                    ),
                  ),
                ),

                // Independent 3-dots Menu Button
                GestureDetector(
                  onTap: () {
                    SongContextMenu.show(
                      context: context,
                      ref: ref,
                      track: track,
                      isNowPlayingContext: false,
                      isFavorite: isFavorite,
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomIcons.moreVertical(
                      size: 18.0,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.iconNavy.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => onPlayTrack(index),
          ),
        );
      },
    );
  }
}
