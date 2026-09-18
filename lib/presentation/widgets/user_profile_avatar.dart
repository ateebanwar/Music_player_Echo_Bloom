import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';

/// Reusable user profile avatar supporting local image files and graceful initials fallback.
class UserProfileAvatar extends StatelessWidget {
  final String? avatarPath;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final bool isDark;

  const UserProfileAvatar({
    super.key,
    this.avatarPath,
    required this.name,
    this.size = 80.0,
    this.onTap,
    this.showEditBadge = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final userInitial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    Widget avatarContent;
    final hasLocalImage = !kIsWeb &&
        avatarPath != null &&
        avatarPath!.isNotEmpty &&
        (avatarPath!.startsWith('/') || avatarPath!.contains(r':\')) &&
        File(avatarPath!).existsSync();

    final isNetworkUrl = avatarPath != null &&
        (avatarPath!.startsWith('http://') ||
         avatarPath!.startsWith('https://') ||
         avatarPath!.startsWith('blob:'));

    if (hasLocalImage) {
      avatarContent = ClipOval(
        child: Image.file(
          File(avatarPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(userInitial),
        ),
      );
    } else if (isNetworkUrl) {
      avatarContent = ClipOval(
        child: Image.network(
          avatarPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(userInitial),
        ),
      );
    } else {
      avatarContent = _buildInitials(userInitial);
    }

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.35),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: avatarContent,
    );

    if (showEditBadge) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  width: 2.0,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: size * 0.18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Widget _buildInitials(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple,
            AppColors.textPurple,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
