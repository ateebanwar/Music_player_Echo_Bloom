import 'package:equatable/equatable.dart';

/// 100% Local-only user profile entity.
class UserProfile extends Equatable {
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String? avatarKey;
  final bool isCompleted;

  const UserProfile({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.avatarKey,
    this.isCompleted = true,
  });

  /// Automatically derives age from date of birth.
  int get age {
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      calculatedAge--;
    }
    return calculatedAge >= 0 ? calculatedAge : 0;
  }

  UserProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarKey,
    bool? isCompleted,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarKey: avatarKey ?? this.avatarKey,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [name, dateOfBirth, gender, avatarKey, isCompleted];
}
