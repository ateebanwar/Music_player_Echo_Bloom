import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/album.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/library/library_providers.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/search/search_controller.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/artist/artist_detail_screen.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// All Songs list screen supporting live Android MediaStore discovery, instant smart search,
/// category filters (All, Songs, Artists, Albums, Playlists), and context actions.
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
    final searchNotifier = ref.read(searchControllerProvider.notifier);
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
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
                        ? 'Search songs, artists, albums, playlists...'
                        : 'Search songs, artists, albums in library...',
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
                              searchNotifier.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  onChanged: (val) {
                    searchNotifier.search(val);
                    setState(() {});
                  },
                ),
              ),
            ),

            // Category Chips (Shown when searching)
            if (isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 2.0, 20.0, 8.0),
                child: SizedBox(
                  height: 36.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('All', SearchCategory.all, searchState.category, isDark, searchNotifier),
                      _buildCategoryChip('Songs', SearchCategory.songs, searchState.category, isDark, searchNotifier),
                      _buildCategoryChip('Artists', SearchCategory.artists, searchState.category, isDark, searchNotifier),
                      _buildCategoryChip('Albums', SearchCategory.albums, searchState.category, isDark, searchNotifier),
                      _buildCategoryChip('Playlists', SearchCategory.playlists, searchState.category, isDark, searchNotifier),
                    ],
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
                searchState: searchState,
                displayedTracks: displayedTracks,
                currentTrack: currentTrack,
                favorites: favoritesState.favorites,
                onToggleFavorite: (t) => favoritesController.toggleFavorite(t),
                onPlayTrack: (tracks, index) => playbackRepo.setQueue(tracks, initialIndex: index),
                onRescan: () => ref.read(libraryControllerProvider.notifier).rescanLibrary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    SearchCategory category,
    SearchCategory activeCategory,
    bool isDark,
    SearchController notifier,
  ) {
    final isSelected = category == activeCategory;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkText : AppColors.textNavy),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedColor: AppColors.primaryPurple,
        side: BorderSide(
          color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        onSelected: (_) => notifier.setCategory(category),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required bool isDark,
    required bool isLoading,
    required bool isSearching,
    required SearchState searchState,
    required List<Track> displayedTracks,
    required Track? currentTrack,
    required List<Track> favorites,
    required void Function(Track) onToggleFavorite,
    required void Function(List<Track>, int) onPlayTrack,
    required VoidCallback onRescan,
  }) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryPurple, strokeWidth: 3.0),
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

    if (searchState.isSearching && displayedTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryPurple, strokeWidth: 3.0),
            const SizedBox(height: 16.0),
            Text(
              searchState.statusMessage ?? 'Searching music...',
              style: AppTypography.artistName.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (isSearching && searchState.errorMessage != null && displayedTracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48.0,
                color: isDark ? AppColors.darkTextMuted.withValues(alpha: 0.6) : AppColors.iconMuted.withValues(alpha: 0.6),
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
                searchState.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.artistName.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Category Views when searching
    if (isSearching) {
      switch (searchState.category) {
        case SearchCategory.artists:
          return _buildArtistsView(context, searchState.artistResults, isDark);
        case SearchCategory.albums:
          return _buildAlbumsView(context, searchState.albumResults, isDark);
        case SearchCategory.playlists:
          return _buildPlaylistsView(context, searchState.playlistResults, isDark);
        case SearchCategory.songs:
          return _buildSongsListView(
            tracks: displayedTracks,
            currentTrack: currentTrack,
            favorites: favorites,
            isDark: isDark,
            onToggleFavorite: onToggleFavorite,
            onPlayTrack: onPlayTrack,
          );
        case SearchCategory.all:
          return _buildAllCategoryView(
            context: context,
            tracks: displayedTracks,
            artists: searchState.artistResults,
            albums: searchState.albumResults,
            playlists: searchState.playlistResults,
            currentTrack: currentTrack,
            favorites: favorites,
            isDark: isDark,
            onToggleFavorite: onToggleFavorite,
            onPlayTrack: onPlayTrack,
            searchQuery: searchState.query,
          );
      }
    }

    // Default: local tracks
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
                color: isDark ? AppColors.darkTextMuted.withValues(alpha: 0.6) : AppColors.iconMuted.withValues(alpha: 0.6),
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
                'Add audio files to your device or switch to Online mode to stream music.',
                textAlign: TextAlign.center,
                style: AppTypography.artistName.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSongsListView(
      tracks: displayedTracks,
      currentTrack: currentTrack,
      favorites: favorites,
      isDark: isDark,
      onToggleFavorite: onToggleFavorite,
      onPlayTrack: onPlayTrack,
    );
  }

  Widget _buildAllCategoryView({
    required BuildContext context,
    required List<Track> tracks,
    required List<Artist> artists,
    required List<Album> albums,
    required List<Playlist> playlists,
    required Track? currentTrack,
    required List<Track> favorites,
    required bool isDark,
    required void Function(Track) onToggleFavorite,
    required void Function(List<Track>, int) onPlayTrack,
    required String searchQuery,
  }) {
    if (tracks.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty) {
      return Center(
        child: Text(
          'No matches found for "$searchQuery"',
          style: AppTypography.artistName.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Artists Section
        if (artists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 8.0),
              child: Text(
                'Artists',
                style: AppTypography.headerTitle.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: artists.length,
                itemBuilder: (context, idx) {
                  final artist = artists[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16.0),
                    onTap: () => ArtistDetailScreen.show(context, artist: artist),
                    child: Container(
                      width: 95.0,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Container(
                              width: 65.0,
                              height: 65.0,
                              color: AppColors.primaryPurple.withValues(alpha: 0.15),
                              child: artist.artworkUri != null && artist.artworkUri!.isNotEmpty
                                  ? Image.network(
                                      artist.artworkUri!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppColors.primaryPurple),
                                    )
                                  : const Icon(Icons.person_rounded, color: AppColors.primaryPurple),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            artist.name,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Albums Section
        if (albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Text(
                'Albums',
                style: AppTypography.headerTitle.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 145.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: albums.length,
                itemBuilder: (context, idx) {
                  final album = albums[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () {
                      PlaylistDetailScreen.show(
                        context,
                        playlistId: 'album_${album.title.hashCode}',
                        initialPlaylist: Playlist(
                          id: 'album_${album.title.hashCode}',
                          name: album.title,
                          description: 'Album by ${album.artist}',
                          artworkUri: album.artworkUri,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                    },
                    child: Container(
                      width: 105.0,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrackArtworkWidget(
                            artworkUri: album.artworkUri,
                            size: 100.0,
                            borderRadius: 12.0,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            album.title,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            album.artist,
                            style: TextStyle(
                              fontSize: 11.0,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Playlists Section
        if (playlists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Text(
                'Playlists',
                style: AppTypography.headerTitle.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 145.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: playlists.length,
                itemBuilder: (context, idx) {
                  final pl = playlists[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () => PlaylistDetailScreen.show(context, playlistId: pl.id, initialPlaylist: pl),
                    child: Container(
                      width: 105.0,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrackArtworkWidget(
                            artworkUri: pl.artworkUri,
                            size: 100.0,
                            borderRadius: 12.0,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            pl.name,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Playlist',
                            style: TextStyle(
                              fontSize: 11.0,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Songs Header
        if (tracks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Text(
                'Songs',
                style: AppTypography.headerTitle.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = tracks[index];
                return _buildSongItem(
                  track: track,
                  index: index,
                  allTracks: tracks,
                  currentTrack: currentTrack,
                  favorites: favorites,
                  isDark: isDark,
                  onToggleFavorite: onToggleFavorite,
                  onPlayTrack: onPlayTrack,
                );
              },
              childCount: tracks.length,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
      ],
    );
  }

  Widget _buildSongsListView({
    required List<Track> tracks,
    required Track? currentTrack,
    required List<Track> favorites,
    required bool isDark,
    required void Function(Track) onToggleFavorite,
    required void Function(List<Track>, int) onPlayTrack,
  }) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 100.0),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _buildSongItem(
          track: track,
          index: index,
          allTracks: tracks,
          currentTrack: currentTrack,
          favorites: favorites,
          isDark: isDark,
          onToggleFavorite: onToggleFavorite,
          onPlayTrack: onPlayTrack,
        );
      },
    );
  }

  Widget _buildSongItem({
    required Track track,
    required int index,
    required List<Track> allTracks,
    required Track? currentTrack,
    required List<Track> favorites,
    required bool isDark,
    required void Function(Track) onToggleFavorite,
    required void Function(List<Track>, int) onPlayTrack,
  }) {
    final isCurrent = currentTrack?.id == track.id;
    final isFavorite = favorites.any((f) => f.id == track.id);

    return Container(
      decoration: NeumorphicDecorations.elevatedCard(
        borderRadius: AppSpacing.roundedArtwork,
        isDark: isDark,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
          leading: TrackArtworkWidget(
            artworkUri: track.artworkUri,
            size: 46.0,
            borderRadius: 12.0,
          ),
          title: Text(
            track.title,
            style: AppTypography.headerTitle.copyWith(
              fontSize: 14.5,
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
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 19.0,
                  color: isFavorite ? AppColors.accentRed : (isDark ? AppColors.darkIcon : AppColors.iconMuted),
                ),
                onPressed: () => onToggleFavorite(track),
              ),
              SongContextMenu(track: track),
            ],
          ),
          onTap: () => onPlayTrack(allTracks, index),
        ),
      ),
    );
  }

  Widget _buildArtistsView(BuildContext context, List<Artist> artists, bool isDark) {
    if (artists.isEmpty) {
      return Center(
        child: Text(
          'No artists found',
          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 100.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 14.0,
        mainAxisSpacing: 14.0,
      ),
      itemCount: artists.length,
      itemBuilder: (context, idx) {
        final artist = artists[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => ArtistDetailScreen.show(context, artist: artist),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    width: 75.0,
                    height: 75.0,
                    color: AppColors.primaryPurple.withValues(alpha: 0.15),
                    child: artist.artworkUri != null && artist.artworkUri!.isNotEmpty
                        ? Image.network(
                            artist.artworkUri!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 36.0, color: AppColors.primaryPurple),
                          )
                        : const Icon(Icons.person_rounded, size: 36.0, color: AppColors.primaryPurple),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  artist.name,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2.0),
                Text(
                  '${artist.trackCount} Tracks',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsView(BuildContext context, List<Album> albums, bool isDark) {
    if (albums.isEmpty) {
      return Center(
        child: Text(
          'No albums found',
          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 100.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 14.0,
        mainAxisSpacing: 14.0,
      ),
      itemCount: albums.length,
      itemBuilder: (context, idx) {
        final album = albums[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () {
            PlaylistDetailScreen.show(
              context,
              playlistId: 'album_${album.title.hashCode}',
              initialPlaylist: Playlist(
                id: 'album_${album.title.hashCode}',
                name: album.title,
                description: 'Album by ${album.artist}',
                artworkUri: album.artworkUri,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: TrackArtworkWidget(
                      artworkUri: album.artworkUri,
                      size: double.infinity,
                      borderRadius: 12.0,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  album.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album.artist,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsView(BuildContext context, List<Playlist> playlists, bool isDark) {
    if (playlists.isEmpty) {
      return Center(
        child: Text(
          'No playlists found',
          style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 100.0),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10.0),
      itemBuilder: (context, idx) {
        final pl = playlists[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () => PlaylistDetailScreen.show(context, playlistId: pl.id, initialPlaylist: pl),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                TrackArtworkWidget(
                  artworkUri: pl.artworkUri,
                  size: 56.0,
                  borderRadius: 12.0,
                  isDark: isDark,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pl.name,
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pl.description != null) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          pl.description!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2.0),
                      Text(
                        '${pl.trackCount} Tracks',
                        style: TextStyle(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
