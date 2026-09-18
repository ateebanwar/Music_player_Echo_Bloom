import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/features/profile/profile_controller.dart';
import 'package:sound_foundry/infrastructure/platform/image_selection_service.dart';
import 'package:sound_foundry/presentation/screens/main_navigation_shell.dart';
import 'package:sound_foundry/presentation/widgets/user_profile_avatar.dart';

/// Local profile setup screen for first launch with photo picker and theme adaptivity.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  DateTime? _selectedDateOfBirth;
  String _selectedGender = 'Male';
  String? _avatarPath;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    // Default DOB to 20 years ago
    _selectedDateOfBirth = DateTime(DateTime.now().year - 20, 1, 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _derivedAge {
    if (_selectedDateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDateOfBirth!.year;
    if (now.month < _selectedDateOfBirth!.month ||
        (now.month == _selectedDateOfBirth!.month && now.day < _selectedDateOfBirth!.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  Future<void> _pickProfilePhoto() async {
    final path = await ImageSelectionService.pickAndSaveProfileImage();
    if (path != null && mounted) {
      setState(() {
        _avatarPath = path;
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialDate = _selectedDateOfBirth ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primaryPurple,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.darkText,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryPurple,
                    onPrimary: Colors.white,
                    surface: AppColors.surface,
                    onSurface: AppColors.textNavy,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    if (_selectedDateOfBirth == null) {
      setState(() {
        _errorMessage = 'Please select your date of birth';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref.read(profileControllerProvider.notifier).saveProfile(
      name: name,
      dateOfBirth: _selectedDateOfBirth!,
      gender: _selectedGender,
      avatarKey: _avatarPath,
    );

    if (!mounted) return;

    if (success) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const MainNavigationShell(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to save local profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? AppColors.darkText : AppColors.iconNavy,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8.0),

                  // Header
                  Text(
                    'Create Profile',
                    style: AppTypography.trackTitle.copyWith(
                      fontSize: 26.0,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Stored 100% locally on your device. Never shared or uploaded.',
                    style: AppTypography.artistName.copyWith(
                      fontSize: 13.0,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Profile Photo Selection Area
                  Center(
                    child: Column(
                      children: [
                        UserProfileAvatar(
                          avatarPath: _avatarPath,
                          name: _nameController.text,
                          size: 96.0,
                          showEditBadge: true,
                          isDark: isDark,
                          onTap: _pickProfilePhoto,
                        ),
                        const SizedBox(height: 10.0),
                        TextButton(
                          onPressed: _pickProfilePhoto,
                          child: const Text(
                            'Choose Profile Photo',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Name Field
                  Text(
                    'Full Name',
                    style: AppTypography.headerTitle.copyWith(
                      fontSize: 14.0,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _nameController,
                    style: AppTypography.headerTitle.copyWith(
                      fontSize: 15.0,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        fontSize: 14.0,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.0),
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20.0),

                  // Date of Birth & Derived Age
                  Text(
                    'Date of Birth',
                    style: AppTypography.headerTitle.copyWith(
                      fontSize: 14.0,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateOfBirth != null
                                ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                : 'Select Date of Birth',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 15.0,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              'Age: $_derivedAge',
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Gender Selection
                  Text(
                    'Gender',
                    style: AppTypography.headerTitle.copyWith(
                      fontSize: 14.0,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((gender) {
                      final isSelected = _selectedGender == gender;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = gender),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryPurple
                                  : (isDark ? AppColors.darkSurface : AppColors.surface),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Center(
                              child: Text(
                                gender,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkText : AppColors.textNavy),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24.0),

                  // Error Message if any
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFE53935), fontSize: 13.0),
                      ),
                    ),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 54.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _handleContinue,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
