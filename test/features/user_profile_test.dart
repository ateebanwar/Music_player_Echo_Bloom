import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';

void main() {
  group('UserProfile and AppMode Domain Tests', () {
    test('UserProfile derives age accurately from date of birth', () {
      final now = DateTime.now();
      final dob25YearsAgo = DateTime(now.year - 25, now.month, now.day);
      final profile = UserProfile(
        name: 'Alex Johnson',
        dateOfBirth: dob25YearsAgo,
        gender: 'Male',
      );

      expect(profile.age, equals(25));
      expect(profile.name, equals('Alex Johnson'));
      expect(profile.gender, equals('Male'));
      expect(profile.isCompleted, isTrue);
    });

    test('UserProfile derives age correctly before birthday in current year', () {
      final now = DateTime.now();
      // DOB next month 20 years ago
      final nextMonth = now.month < 12 ? now.month + 1 : 1;
      final yearOffset = now.month < 12 ? 20 : 19;
      final dob = DateTime(now.year - yearOffset, nextMonth, 15);
      final profile = UserProfile(
        name: 'Jordan',
        dateOfBirth: dob,
        gender: 'Female',
      );

      expect(profile.age, equals(yearOffset - 1));
    });

    test('AppMode extensions provide clear display name and descriptions', () {
      expect(AppMode.offline.displayName, equals('Offline Mode'));
      expect(AppMode.online.displayName, equals('Online Mode'));
      expect(AppMode.offline.description, contains('0 network operations'));
      expect(AppMode.online.description, contains('future streaming'));
    });
  });
}
