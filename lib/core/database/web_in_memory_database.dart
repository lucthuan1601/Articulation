import 'dart:async';
import 'package:articulation/core/database/app_database.dart';
import 'package:articulation/core/database/seed_data.dart';
import 'package:articulation/features/habit_tracking/data/dao/practice_session_dao.dart';
import 'package:articulation/features/habit_tracking/data/dao/user_dao.dart';
import 'package:articulation/features/habit_tracking/data/models/practice_session_entity.dart';
import 'package:articulation/features/habit_tracking/data/models/user_entity.dart';
import 'package:articulation/features/pronunciation/data/dao/lesson_dao.dart';
import 'package:articulation/features/pronunciation/data/dao/pronunciation_result_dao.dart';
import 'package:articulation/features/pronunciation/data/models/lesson_entity.dart';
import 'package:articulation/features/pronunciation/data/models/pronunciation_result_entity.dart';

/// Database dự phòng chạy hoàn toàn trong bộ nhớ (In-Memory) cho Web.
///
/// Giúp ứng dụng hoạt động 100% ổn định trên nền tảng Web mà không phụ thuộc
/// vào SharedWorker hoặc hạn chế SharedArrayBuffer/Cross-Origin-Opener-Policy của trình duyệt.
class WebInMemoryDatabase extends AppDatabase {
  final _userDao = InMemoryUserDao();
  final _lessonDao = InMemoryLessonDao();
  final _sessionDao = InMemoryPracticeSessionDao();
  final _resultDao = InMemoryPronunciationResultDao();

  WebInMemoryDatabase() {
    changeListener = StreamController<String>.broadcast();
    // Preload dữ liệu bài học mẫu
    _lessonDao.seedInitialLessons();
  }

  @override
  UserDao get userDao => _userDao;

  @override
  LessonDao get lessonDao => _lessonDao;

  @override
  PracticeSessionDao get practiceSessionDao => _sessionDao;

  @override
  PronunciationResultDao get pronunciationResultDao => _resultDao;
}

class InMemoryUserDao implements UserDao {
  final Map<String, UserEntity> _users = {
    'local_user': UserEntity(
      id: 'local_user',
      name: 'Học viên',
      email: 'learner@articulation.app',
      avatarUrl: null,
      dailyGoalMinutes: 15,
      currentStreak: 5,
      longestStreak: 12,
      lastPracticeDate: DateTime.now().subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
      notificationTime: '08:00',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      isNotificationEnabled: true,
    ),
  };

  @override
  Future<List<UserEntity>> findAllUsers() async => _users.values.toList();

  @override
  Future<UserEntity?> findUserById(String id) async => _users[id];

  @override
  Future<void> insertUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> deleteUser(UserEntity user) async {
    _users.remove(user.id);
  }

  @override
  Future<void> updateStreak(String id, int currentStreak, int longestStreak, int lastPracticeDate) async {
    final existing = _users[id];
    if (existing != null) {
      _users[id] = UserEntity(
        id: existing.id,
        name: existing.name,
        email: existing.email,
        avatarUrl: existing.avatarUrl,
        dailyGoalMinutes: existing.dailyGoalMinutes,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastPracticeDate: lastPracticeDate,
        notificationTime: existing.notificationTime,
        createdAt: existing.createdAt,
        isNotificationEnabled: existing.isNotificationEnabled,
      );
    }
  }

  @override
  Future<void> updateDailyGoal(String id, int minutes) async {
    final existing = _users[id];
    if (existing != null) {
      _users[id] = UserEntity(
        id: existing.id,
        name: existing.name,
        email: existing.email,
        avatarUrl: existing.avatarUrl,
        dailyGoalMinutes: minutes,
        currentStreak: existing.currentStreak,
        longestStreak: existing.longestStreak,
        lastPracticeDate: existing.lastPracticeDate,
        notificationTime: existing.notificationTime,
        createdAt: existing.createdAt,
        isNotificationEnabled: existing.isNotificationEnabled,
      );
    }
  }

  @override
  Future<void> updateNotificationSettings(String id, String time, int enabled) async {
    final existing = _users[id];
    if (existing != null) {
      _users[id] = UserEntity(
        id: existing.id,
        name: existing.name,
        email: existing.email,
        avatarUrl: existing.avatarUrl,
        dailyGoalMinutes: existing.dailyGoalMinutes,
        currentStreak: existing.currentStreak,
        longestStreak: existing.longestStreak,
        lastPracticeDate: existing.lastPracticeDate,
        notificationTime: time,
        createdAt: existing.createdAt,
        isNotificationEnabled: enabled == 1,
      );
    }
  }
}

class InMemoryLessonDao implements LessonDao {
  final Map<String, LessonEntity> _lessons = {};

  void seedInitialLessons() {
    for (final item in SeedData.getAllLessons()) {
      _lessons[item['id'] as String] = LessonEntity(
        id: item['id'] as String,
        content: item['content'] as String,
        ipaTranscript: item['ipaTranscript'] as String,
        vietnameseMeaning: item['vietnameseMeaning'] as String,
        type: item['type'] as String,
        difficulty: item['difficulty'] as String,
        category: item['category'] as String,
        audioUrl: item['audioUrl'] as String?,
        orderIndex: item['orderIndex'] as int,
      );
    }
  }

  @override
  Future<List<LessonEntity>> findAllLessons() async {
    final list = _lessons.values.toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<LessonEntity?> findLessonById(String id) async => _lessons[id];

  @override
  Future<List<LessonEntity>> findLessonsByType(String type) async {
    return _lessons.values.where((l) => l.type == type).toList();
  }

  @override
  Future<List<LessonEntity>> findLessonsByDifficulty(String difficulty) async {
    return _lessons.values.where((l) => l.difficulty == difficulty).toList();
  }

  @override
  Future<List<LessonEntity>> findLessonsByCategory(String category) async {
    return _lessons.values.where((l) => l.category == category).toList();
  }

  @override
  Future<List<LessonEntity>> findLessonsByTypeAndDifficulty(String type, String difficulty) async {
    return _lessons.values.where((l) => l.type == type && l.difficulty == difficulty).toList();
  }

  @override
  Future<void> insertLesson(LessonEntity lesson) async {
    _lessons[lesson.id] = lesson;
  }

  @override
  Future<void> insertLessons(List<LessonEntity> lessons) async {
    for (final l in lessons) {
      _lessons[l.id] = l;
    }
  }

  @override
  Future<void> updateLesson(LessonEntity lesson) async {
    _lessons[lesson.id] = lesson;
  }

  @override
  Future<void> deleteLesson(LessonEntity lesson) async {
    _lessons.remove(lesson.id);
  }
}

class InMemoryPracticeSessionDao implements PracticeSessionDao {
  final Map<String, PracticeSessionEntity> _sessions = {
    'demo_session_1': PracticeSessionEntity(
      id: 'demo_session_1',
      userId: 'local_user',
      date: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      durationSeconds: 620,
      totalScore: 88.5,
      lessonsCompleted: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
    ),
    'demo_session_2': PracticeSessionEntity(
      id: 'demo_session_2',
      userId: 'local_user',
      date: DateTime.now().millisecondsSinceEpoch,
      durationSeconds: 480,
      totalScore: 92.0,
      lessonsCompleted: 2,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  };

  @override
  Future<List<PracticeSessionEntity>> findAllSessions() async {
    final list = _sessions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<PracticeSessionEntity?> findSessionById(String id) async => _sessions[id];

  @override
  Future<List<PracticeSessionEntity>> findSessionsByUserId(String userId) async {
    final list = _sessions.values.where((s) => s.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<PracticeSessionEntity>> findSessionsByDateRange(String userId, int startDate, int endDate) async {
    final list = _sessions.values
        .where((s) => s.userId == userId && s.date >= startDate && s.date <= endDate)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<PracticeSessionEntity?> findTodaySession(String userId, int todayStart, int todayEnd) async {
    final matches = _sessions.values
        .where((s) => s.userId == userId && s.date >= todayStart && s.date <= todayEnd)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<int?> getTotalPracticeTime(String userId) async {
    final userSessions = _sessions.values.where((s) => s.userId == userId);
    if (userSessions.isEmpty) return null;
    return userSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  @override
  Future<double?> getAverageScore(String userId) async {
    final userSessions = _sessions.values.where((s) => s.userId == userId).toList();
    if (userSessions.isEmpty) return null;
    final total = userSessions.fold<double>(0.0, (sum, s) => sum + s.totalScore);
    return total / userSessions.length;
  }

  @override
  Future<int?> getSessionCount(String userId) async {
    final count = _sessions.values.where((s) => s.userId == userId).length;
    return count == 0 ? null : count;
  }

  @override
  Future<void> insertSession(PracticeSessionEntity session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<void> updateSession(PracticeSessionEntity session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<void> deleteSession(PracticeSessionEntity session) async {
    _sessions.remove(session.id);
  }
}

class InMemoryPronunciationResultDao implements PronunciationResultDao {
  final Map<String, PronunciationResultEntity> _results = {};

  @override
  Future<List<PronunciationResultEntity>> findAllResults() async => _results.values.toList();

  @override
  Future<PronunciationResultEntity?> findResultById(String id) async => _results[id];

  @override
  Future<List<PronunciationResultEntity>> findResultsBySessionId(String sessionId) async {
    final list = _results.values.where((r) => r.sessionId == sessionId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<List<PronunciationResultEntity>> findResultsByUserId(String userId) async {
    final list = _results.values.where((r) => r.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<PronunciationResultEntity>> findResultsByLessonId(String userId, String lessonId) async {
    final list = _results.values.where((r) => r.userId == userId && r.lessonId == lessonId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<double?> getAverageAccuracy(String userId) async {
    final list = _results.values.where((r) => r.userId == userId).toList();
    if (list.isEmpty) return null;
    return list.fold<double>(0.0, (sum, r) => sum + r.accuracyScore) / list.length;
  }

  @override
  Future<double?> getBestScoreForLesson(String userId, String lessonId) async {
    final list = _results.values.where((r) => r.userId == userId && r.lessonId == lessonId).toList();
    if (list.isEmpty) return null;
    return list.map((r) => r.overallScore).reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<List<PronunciationResultEntity>> getRecentResults(String userId, int limit) async {
    final list = _results.values.where((r) => r.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  @override
  Future<void> insertResult(PronunciationResultEntity result) async {
    _results[result.id] = result;
  }

  @override
  Future<void> updateResult(PronunciationResultEntity result) async {
    _results[result.id] = result;
  }

  @override
  Future<void> deleteResult(PronunciationResultEntity result) async {
    _results.remove(result.id);
  }
}
