import 'package:articulation/features/habit_tracking/domain/entities/practice_session.dart';
import 'package:articulation/features/habit_tracking/domain/entities/user.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';
import 'package:articulation/features/habit_tracking/domain/usecases/calculate_streak_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePracticeSessionRepository implements PracticeSessionRepository {
  _FakePracticeSessionRepository(this.sessions);

  final List<PracticeSession> sessions;

  @override
  Future<List<PracticeSession>> getSessionsByUserId(String userId) async =>
      sessions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.user);

  final User? user;
  int? updatedCurrentStreak;
  int? updatedLongestStreak;
  DateTime? updatedLastPracticeDate;

  @override
  Future<User?> getUserById(String id) async => user;

  @override
  Future<void> updateStreak(
    String userId,
    int currentStreak,
    int longestStreak,
    DateTime lastPracticeDate,
  ) async {
    updatedCurrentStreak = currentStreak;
    updatedLongestStreak = longestStreak;
    updatedLastPracticeDate = lastPracticeDate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CalculateStreakUseCase', () {
    test('clears an expired streak while retaining the historical record',
        () async {
      final now = DateTime.now();
      final lastPracticeDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 3));
      final user = User(
        id: 'local_user',
        name: 'Test',
        email: 'test@example.com',
        currentStreak: 3,
        longestStreak: 8,
        lastPracticeDate: lastPracticeDate,
        createdAt: now,
      );
      final userRepository = _FakeUserRepository(user);
      final useCase = CalculateStreakUseCase(
        sessionRepository: _FakePracticeSessionRepository(const []),
        userRepository: userRepository,
      );

      final result = await useCase.execute(user.id);

      expect(result.currentStreak, 0);
      expect(result.longestStreak, 8);
      expect(result.lastPracticeDate, lastPracticeDate);
      expect(userRepository.updatedCurrentStreak, 0);
      expect(userRepository.updatedLongestStreak, 8);
      expect(userRepository.updatedLastPracticeDate, lastPracticeDate);
    });

    test('does not lower a previously recorded longest streak', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final user = User(
        id: 'local_user',
        name: 'Test',
        email: 'test@example.com',
        longestStreak: 12,
        createdAt: now,
      );
      final userRepository = _FakeUserRepository(user);
      final useCase = CalculateStreakUseCase(
        sessionRepository: _FakePracticeSessionRepository([
          PracticeSession(
            id: 'session-1',
            userId: user.id,
            date: today,
            createdAt: now,
          ),
        ]),
        userRepository: userRepository,
      );

      final result = await useCase.execute(user.id);

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 12);
      expect(userRepository.updatedCurrentStreak, 1);
      expect(userRepository.updatedLongestStreak, 12);
    });
  });
}
