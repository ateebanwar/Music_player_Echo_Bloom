import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';

/// Contract for local-only user profile persistence and setup completion state.
abstract class UserProfileRepository {
  Future<Result<UserProfile?, Failure>> getProfile();
  Future<Result<void, Failure>> saveProfile(UserProfile profile);
  Future<Result<bool, Failure>> isSetupCompleted();
  Future<Result<void, Failure>> setSetupCompleted(bool completed);
}
