import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';
import 'package:sound_foundry/features/profile/profile_controller.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/infrastructure/platform/image_selection_service.dart';
import 'package:sound_foundry/presentation/screens/onboarding/welcome_screen.dart';
import 'package:sound_foundry/presentation/widgets/user_profile_avatar.dart';

/// Dedicated Profile Screen displaying local user information and providing Edit & Sign Out actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final isDark = ref.watch(isDarkModeProvider);

    final userName = profile?.name ?? 'Local User';
    final dob = profile?.dateOfBirth;
    final dobText = dob != null ? '${dob.day}/${dob.month}/${dob.year}' : 'Not set';
    final ageText = profile != null ? '${profile.age} years old' : 'Unknown';
    final genderText = profile?.gender ?? 'Not specified';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 24.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppColors.darkText : AppColors.iconNavy,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Profile',
                      style: AppTypography.trackTitle.copyWith(
                        fontSize: 22.0,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primaryPurple),
                      onPressed: () => _showEditProfileDialog(context, ref, profile),
                    ),
                  ],
                ),
              ),

              // Profile Avatar & Card
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  children: [
                    Center(
                      child: UserProfileAvatar(
                        avatarPath: profile?.avatarKey,
                        name: userName,
                        size: 96.0,
                        isDark: isDark,
                        showEditBadge: true,
                        onTap: () => _showEditProfileDialog(context, ref, profile),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Center(
                      child: Text(
                        userName,
                        style: AppTypography.trackTitle.copyWith(
                          fontSize: 22.0,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Center(
                      child: Text(
                        '100% Local Profile • Private',
                        style: AppTypography.artistName.copyWith(
                          fontSize: 13.0,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28.0),

                    // Information Tiles
                    _buildInfoCard(
                      context,
                      isDark: isDark,
                      title: 'Date of Birth',
                      value: dobText,
                      icon: Icons.calendar_today_rounded,
                    ),
                    const SizedBox(height: 12.0),
                    _buildInfoCard(
                      context,
                      isDark: isDark,
                      title: 'Age',
                      value: ageText,
                      icon: Icons.cake_rounded,
                    ),
                    const SizedBox(height: 12.0),
                    _buildInfoCard(
                      context,
                      isDark: isDark,
                      title: 'Gender',
                      value: genderText,
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 36.0),

                    // Edit Profile Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18.0),
                      label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => _showEditProfileDialog(context, ref, profile),
                    ),

                    const SizedBox(height: 14.0),

                    // Local Sign Out / Reset Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: const BorderSide(color: Color(0xFFE53935), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18.0),
                      label: const Text('Sign Out (Reset Setup)', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: AppColors.primaryPurple),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: AppTypography.headerTitle.copyWith(
                    fontSize: 15.0,
                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile? current) {
    final nameController = TextEditingController(text: current?.name ?? '');
    DateTime selectedDob = current?.dateOfBirth ?? DateTime(2000, 1, 1);
    String selectedGender = current?.gender ?? 'Male';
    String? selectedAvatarPath = current?.avatarKey;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profile', style: AppTypography.trackTitle.copyWith(fontSize: 20.0)),
                    const SizedBox(height: 16.0),

                    // Avatar in Edit Modal
                    Center(
                      child: UserProfileAvatar(
                        avatarPath: selectedAvatarPath,
                        name: nameController.text,
                        size: 80.0,
                        showEditBadge: true,
                        isDark: isDark,
                        onTap: () async {
                          final path = await ImageSelectionService.pickAndSaveProfileImage();
                          if (path != null) {
                            setModalState(() => selectedAvatarPath = path);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        filled: true,
                        fillColor: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14.0),

                    // Date of Birth Row
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date of Birth'),
                      subtitle: Text('${selectedDob.day}/${selectedDob.month}/${selectedDob.year}'),
                      trailing: const Icon(Icons.calendar_today_rounded, size: 20.0, color: AppColors.primaryPurple),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDob,
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDob = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8.0),

                    // Gender Choice
                    Row(
                      children: ['Male', 'Female', 'Other'].map((g) {
                        final isSelected = selectedGender == g;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(g),
                              selected: isSelected,
                              selectedColor: AppColors.primaryPurple,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textNavy),
                              onSelected: (_) => setModalState(() => selectedGender = g),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20.0),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          await ref.read(profileControllerProvider.notifier).saveProfile(
                            name: name,
                            dateOfBirth: selectedDob,
                            gender: selectedGender,
                            avatarKey: selectedAvatarPath,
                          );

                          if (context.mounted) {
                            Navigator.pop(sheetCtx);
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out? Your local profile setup will be reset, and you will return to the Welcome screen. Your downloaded music and playlists will remain untouched.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await ref.read(profileControllerProvider.notifier).resetProfile();

                if (context.mounted) {
                  await Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
