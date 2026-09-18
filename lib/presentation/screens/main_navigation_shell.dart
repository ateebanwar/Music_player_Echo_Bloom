import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/all_songs/all_songs_screen.dart';
import 'package:sound_foundry/presentation/screens/favorites/favorites_screen.dart';
import 'package:sound_foundry/presentation/screens/now_playing/now_playing_screen.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlists_screen.dart';
import 'package:sound_foundry/presentation/widgets/app_drawer.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_bottom_nav.dart';

/// Provider controlling the active navigation tab index.
/// Defaults to index 1 (All Songs) as the primary post-setup and startup screen.
final mainNavIndexProvider = StateProvider<int>((ref) => 1);

/// Root navigation shell hosting all 4 destinations and preserving playback lifecycle across tab switches.
class MainNavigationShell extends ConsumerStatefulWidget {
  final int? initialIndex;

  const MainNavigationShell({super.key, this.initialIndex});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      Future.microtask(() {
        if (mounted) {
          ref.read(mainNavIndexProvider.notifier).state = widget.initialIndex!;
        }
      });
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentIndex = ref.watch(mainNavIndexProvider);

    final screens = [
      NowPlayingScreen(onMenuTap: _openDrawer),
      AllSongsScreen(onMenuTap: _openDrawer),
      FavoritesScreen(onMenuTap: _openDrawer),
      PlaylistsScreen(onMenuTap: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Screen destinations preserved via IndexedStack
          Positioned.fill(
            child: IndexedStack(
              index: currentIndex,
              children: screens,
            ),
          ),

          // Floating Neumorphic Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: NeumorphicBottomNav(
                currentIndex: currentIndex,
                isDark: isDark,
                onIndexChanged: (index) {
                  ref.read(mainNavIndexProvider.notifier).state = index;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
