import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';

/// Top header containing the menu button, dropdown chevron, title, and options.
class NowPlayingHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onOptionsTap;
  final bool? isDark;

  const NowPlayingHeader({
    super.key,
    this.onMenuTap,
    this.onOptionsTap,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final iconColor = effectiveIsDark ? AppColors.darkIcon : AppColors.iconNavy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Hamburger Menu Icon
          Semantics(
            label: 'Menu',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onMenuTap,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: CustomIcons.menu(size: 22.0, color: iconColor),
              ),
            ),
          ),

          // Center: Now Playing Title
          Semantics(
            label: 'Now Playing',
            header: true,
            child: Text(
              'Now Playing',
              style: AppTypography.headerTitle.copyWith(
                fontSize: 17.0,
                color: effectiveIsDark ? AppColors.darkText : AppColors.textNavy,
              ),
            ),
          ),

          // Right: 3-dots Vertical Menu
          Semantics(
            label: 'More options',
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onOptionsTap,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: CustomIcons.moreVertical(size: 20.0, color: iconColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
