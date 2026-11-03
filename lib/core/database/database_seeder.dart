import 'package:articulation/core/database/app_database.dart';
import 'package:articulation/core/database/seed_data.dart';
import 'package:articulation/features/pronunciation/data/models/lesson_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service để seed dữ liệu bài học mẫu vào database
/// Chỉ chạy 1 lần khi app khởi động lần đầu
class DatabaseSeeder {
  final AppDatabase _database;

  DatabaseSeeder(this._database);

  /// Key để check đã seed chưa trong SharedPreferences
  static const String _seedKey = 'db_seeded_v1';

  /// Seed dữ liệu nếu chưa được seed
  Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_seedKey) ?? false;

    if (!alreadySeeded) {
      await _seedLessons();
      await prefs.setBool(_seedKey, true);
    }
  }

  /// Insert tất cả bài học mẫu vào database
  Future<void> _seedLessons() async {
    final allLessons = SeedData.getAllLessons();
    final lessonEntities = allLessons.map((data) {
      return LessonEntity(
        id: data['id'] as String,
        content: data['content'] as String,
        ipaTranscript: data['ipaTranscript'] as String,
        vietnameseMeaning: data['vietnameseMeaning'] as String,
        type: data['type'] as String,
        difficulty: data['difficulty'] as String,
        category: data['category'] as String,
        audioUrl: data['audioUrl'] as String?,
        orderIndex: data['orderIndex'] as int,
      );
    }).toList();

    // Batch insert với OnConflictStrategy.replace
    await _database.lessonDao.insertLessons(lessonEntities);
  }

  /// Reset và seed lại toàn bộ dữ liệu (dùng cho testing)
  Future<void> resetAndSeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seedKey);
    await seedIfNeeded();
  }
}
