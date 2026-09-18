import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';

/// Floating neumorphic bottom navigation bar with 4 destinations.
class NeumorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool? isDark;

  const NeumorphicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
      child: Container(
        height: 72.0,
        decoration: BoxDecoration(
          color: effectiveIsDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: AppSpacing.roundedNavContainer,
          boxShadow: [
            BoxShadow(
              color: effectiveIsDark ? Colors.black.withValues(alpha: 0.3) : AppColors.shadowDark,
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tab 0: Now Playing (Active Pill)
            _buildNavItem(
              context: context,
              index: 0,
              label: 'Now Playing',
              isDark: effectiveIsDark,
              iconBuilder: (isActive) => CustomIcons.musicNote(
                size: 20.0,
                color: isActive ? AppColors.primaryPurple : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy),
              ),
            ),

            // Tab 1: All Songs (Disc)
            _buildNavItem(
              context: context,
              index: 1,
              label: 'All Songs',
              isDark: effectiveIsDark,
              iconBuilder: (isActive) => CustomIcons.disc(
                size: 22.0,
                color: isActive ? AppColors.primaryPurple : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy),
              ),
            ),

            // Tab 2: Likes (Heart)
            _buildNavItem(
              context: context,
              index: 2,
              label: 'Likes',
              isDark: effectiveIsDark,
              iconBuilder: (isActive) => CustomIcons.heart(
                size: 20.0,
                color: isActive ? AppColors.primaryPurple : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy),
                isFilled: true,
              ),
            ),

            // Tab 3: Library (Grid)
            _buildNavItem(
              context: context,
              index: 3,
              label: 'Library',
              isDark: effectiveIsDark,
              iconBuilder: (isActive) => CustomIcons.playlistGrid(
                size: 20.0,
                color: isActive ? AppColors.primaryPurple : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required bool isDark,
    required Widget Function(bool isActive) iconBuilder,
  }) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onIndexChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 4.0,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 22.0,
                width: 22.0,
                child: Center(child: iconBuilder(isActive)),
              ),
              const SizedBox(height: 2.0),
              Text(
                label,
                style: isActive
                    ? AppTypography.navLabelActive
                    : (isDark
                        ? AppTypography.navLabelInactive.copyWith(color: AppColors.darkTextMuted)
                        : AppTypography.navLabelInactive),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
