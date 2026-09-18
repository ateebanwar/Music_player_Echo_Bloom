import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';
import 'package:sound_foundry/domain/repositories/user_profile_repository.dart';

class ProfileState extends Equatable {
  final bool isLoading;
  final bool isSetupCompleted;
  final UserProfile? profile;
  final String? errorMessage;

  const ProfileState({
    this.isLoading = true,
    this.isSetupCompleted = false,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSetupCompleted,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSetupCompleted, profile, errorMessage];
}

class ProfileController extends StateNotifier<ProfileState> {
  final UserProfileRepository _repository;

  ProfileController(this._repository) : super(const ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final profileRes = await _repository.getProfile();
    final setupRes = await _repository.isSetupCompleted();

    final profile = profileRes.valueOrNull;
    final isCompleted = setupRes.valueOrNull ?? (profile != null && profile.isCompleted);

    state = state.copyWith(
      isLoading: false,
      isSetupCompleted: isCompleted,
      profile: profile,
    );
  }

  Future<bool> saveProfile({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    String? avatarKey,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final userProfile = UserProfile(
      name: trimmedName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      avatarKey: avatarKey,
      isCompleted: true,
    );

    final saveRes = await _repository.saveProfile(userProfile);
    if (saveRes.isOk) {
      await _repository.setSetupCompleted(true);
      state = state.copyWith(
        isLoading: false,
        isSetupCompleted: true,
        profile: userProfile,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: saveRes.failureOrNull?.message ?? 'Failed to save profile',
      );
      return false;
    }
  }

  Future<void> resetProfile() async {
    await _repository.setSetupCompleted(false);
    state = const ProfileState(isLoading: false, isSetupCompleted: false, profile: null);
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return ProfileController(repository);
});
