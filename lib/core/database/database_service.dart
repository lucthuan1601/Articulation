import 'package:articulation/core/database/app_database.dart';
import 'package:articulation/core/database/seed_data.dart';
import 'package:articulation/features/pronunciation/data/models/lesson_entity.dart';
import 'package:articulation/features/habit_tracking/data/models/user_entity.dart';
import 'package:uuid/uuid.dart';

/// Service quản lý database: migration, seeding, backup
/// Thuộc nhiệm vụ của Lục Văn Thuận - Task 1 (Database Design)
class DatabaseService {
  final AppDatabase _database;
  static const _uuid = Uuid();

  DatabaseService(this._database);

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  /// Khởi tạo database với dữ liệu mặc định
  /// Chạy lần đầu khi app được cài đặt
  Future<void> initializeDatabase() async {
    await _seedDefaultLessons();
  }

  /// Seed dữ liệu bài học mặc định
  Future<void> _seedDefaultLessons() async {
    // Kiểm tra xem đã có dữ liệu chưa
    final existingLessons = await _database.lessonDao.findAllLessons();
    if (existingLessons.isNotEmpty) return;

    final allLessons = SeedData.getAllLessons();
    final entities = allLessons.map((data) => LessonEntity(
      id: data['id'] as String,
      content: data['content'] as String,
      ipaTranscript: data['ipaTranscript'] as String,
      vietnameseMeaning: data['vietnameseMeaning'] as String,
      type: data['type'] as String,
      difficulty: data['difficulty'] as String,
      category: data['category'] as String,
      audioUrl: data['audioUrl'] as String?,
      orderIndex: data['orderIndex'] as int,
    )).toList();

    await _database.lessonDao.insertLessons(entities);
  }

  // ══════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  /// Tạo user mặc định nếu chưa có (cho chế độ offline/local)
  Future<UserEntity> getOrCreateDefaultUser() async {
    const defaultUserId = 'local_user';
    final existing = await _database.userDao.findUserById(defaultUserId);
    
    if (existing != null) return existing;

    final user = UserEntity(
      id: defaultUserId,
      name: 'Người dùng',
      email: 'local@articulation.app',
      avatarUrl: null,
      dailyGoalMinutes: 15,
      currentStreak: 0,
      longestStreak: 0,
      lastPracticeDate: null,
      notificationTime: '08:00',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isNotificationEnabled: true,
    );

    await _database.userDao.insertUser(user);
    return user;
  }

  // ══════════════════════════════════════════════════════════════
  // STATISTICS HELPERS
  // ══════════════════════════════════════════════════════════════

  /// Lấy thống kê tổng quan cho user
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    final totalTime = await _database.practiceSessionDao
        .getTotalPracticeTime(userId);
    final avgScore = await _database.practiceSessionDao
        .getAverageScore(userId);
    final sessionCount = await _database.practiceSessionDao
        .getSessionCount(userId);
    final avgAccuracy = await _database.pronunciationResultDao
        .getAverageAccuracy(userId);

    return {
      'totalPracticeTimeSeconds': totalTime ?? 0,
      'averageSessionScore': avgScore ?? 0.0,
      'totalSessions': sessionCount ?? 0,
      'averageAccuracy': avgAccuracy ?? 0.0,
    };
  }

  // ══════════════════════════════════════════════════════════════
  // DATA CLEANUP
  // ══════════════════════════════════════════════════════════════

  /// Xóa toàn bộ dữ liệu (dùng cho testing hoặc reset app)
  Future<void> clearAllData() async {
    // Floor không hỗ trợ clearAllTables trực tiếp
    // Cần implement ở mỗi DAO hoặc sử dụng raw query
    // TODO: Implement when needed for production
  }

  /// Tạo ID mới dạng UUID v4
  static String generateId() {
    return _uuid.v4();
  }
}
