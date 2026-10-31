import '../entities/lesson.dart';

/// Repository interface định nghĩa các phương thức tương tác với dữ liệu Lesson
abstract class LessonRepository {
  /// Lấy toàn bộ danh sách bài học
  Future<List<Lesson>> getAllLessons();

  /// Lấy chi tiết bài học theo ID
  Future<Lesson?> getLessonById(String id);

  /// Lọc bài học theo loại (word, sentence, paragraph)
  Future<List<Lesson>> getLessonsByType(LessonType type);

  /// Lọc bài học theo độ khó (beginner, intermediate, advanced)
  Future<List<Lesson>> getLessonsByDifficulty(DifficultyLevel difficulty);

  /// Lọc bài học theo chủ đề/danh mục
  Future<List<Lesson>> getLessonsByCategory(String category);

  /// Lọc bài học kết hợp loại và độ khó
  Future<List<Lesson>> getLessonsByTypeAndDifficulty(
    LessonType type,
    DifficultyLevel difficulty,
  );

  /// Thêm hoặc cập nhật một bài học
  Future<void> saveLesson(Lesson lesson);

  /// Thêm hàng loạt bài học (batch seed)
  Future<void> saveLessons(List<Lesson> lessons);

  /// Xóa bài học theo ID
  Future<void> deleteLesson(String id);
}
