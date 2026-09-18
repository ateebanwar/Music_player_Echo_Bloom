import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';
import 'package:sound_foundry/domain/repositories/user_profile_repository.dart';
import 'package:sound_foundry/infrastructure/storage/key_value_store.dart';

/// Local SQLite-backed implementation of [UserProfileRepository].
class UserProfileRepositoryImpl implements UserProfileRepository {
  final KeyValueStore _keyValueStore;

  static const String _keyProfileName = 'profile_name';
  static const String _keyProfileDob = 'profile_dob';
  static const String _keyProfileGender = 'profile_gender';
  static const String _keyProfileAvatar = 'profile_avatar';
  static const String _keyIsSetupCompleted = 'is_setup_completed';

  const UserProfileRepositoryImpl(this._keyValueStore);

  @override
  Future<Result<UserProfile?, Failure>> getProfile() async {
    try {
      final name = await _keyValueStore.getString(_keyProfileName);
      final dobStr = await _keyValueStore.getString(_keyProfileDob);
      final gender = await _keyValueStore.getString(_keyProfileGender);
      final avatar = await _keyValueStore.getString(_keyProfileAvatar);
      final isCompleted = await _keyValueStore.getBool(_keyIsSetupCompleted) ?? false;

      if (name == null || dobStr == null || gender == null) {
        return const Result.ok(null);
      }

      final dob = DateTime.tryParse(dobStr);
      if (dob == null) {
        return const Result.ok(null);
      }

      return Result.ok(UserProfile(
        name: name,
        dateOfBirth: dob,
        gender: gender,
        avatarKey: avatar,
        isCompleted: isCompleted,
      ));
    } catch (e) {
      return Result.err(StorageFailure(
        message: 'Failed to read local profile: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> saveProfile(UserProfile profile) async {
    try {
      await _keyValueStore.setString(_keyProfileName, profile.name);
      await _keyValueStore.setString(_keyProfileDob, profile.dateOfBirth.toIso8601String());
      await _keyValueStore.setString(_keyProfileGender, profile.gender);
      if (profile.avatarKey != null) {
        await _keyValueStore.setString(_keyProfileAvatar, profile.avatarKey!);
      }
      await _keyValueStore.setBool(_keyIsSetupCompleted, profile.isCompleted);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(StorageFailure(
        message: 'Failed to save local profile: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<bool, Failure>> isSetupCompleted() async {
    try {
      final completed = await _keyValueStore.getBool(_keyIsSetupCompleted);
      return Result.ok(completed ?? false);
    } catch (e) {
      return Result.err(StorageFailure(
        message: 'Failed to check setup state: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> setSetupCompleted(bool completed) async {
    try {
      await _keyValueStore.setBool(_keyIsSetupCompleted, completed);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(StorageFailure(
        message: 'Failed to save setup state: $e',
        cause: e,
      ));
    }
  }
}
