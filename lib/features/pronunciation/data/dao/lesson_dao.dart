/// DAO (Data Access Object) cho bảng bài học phát âm.
///
/// Cung cấp các phương thức truy vấn CRUD và các truy vấn lọc
/// để quản lý dữ liệu bài học trong ứng dụng luyện phát âm tiếng Anh.
///
/// Bao gồm:
/// - Truy vấn cơ bản: tìm tất cả, tìm theo ID, thêm, cập nhật, xóa
/// - Lọc theo loại bài học (word, sentence, paragraph, conversation)
/// - Lọc theo mức độ khó (beginner, intermediate, advanced)
/// - Lọc theo danh mục (vowels, consonants, diphthongs, v.v.)
/// - Hỗ trợ thêm hàng loạt (batch insert) với xử lý xung đột
library;

import 'package:floor/floor.dart';

import 'package:articulation/features/pronunciation/data/models/lesson_entity.dart';

/// DAO quản lý dữ liệu bài học phát âm trong cơ sở dữ liệu.
///
/// Sử dụng Floor ORM để ánh xạ các truy vấn SQL sang các phương thức Dart.
/// Hỗ trợ lọc bài học theo nhiều tiêu chí khác nhau.
@dao
abstract class LessonDao {
  /// Lấy danh sách tất cả bài học từ cơ sở dữ liệu.
  ///
  /// Trả về [Future<List<LessonEntity>>] chứa tất cả bản ghi bài học.
  @Query('SELECT * FROM lessons')
  Future<List<LessonEntity>> findAllLessons();

  /// Tìm bài học theo ID duy nhất.
  ///
  /// [id] - Mã định danh duy nhất của bài học (UUID).
  /// Trả về [Future<LessonEntity?>] hoặc null nếu không tìm thấy.
  @Query('SELECT * FROM lessons WHERE id = :id')
  Future<LessonEntity?> findLessonById(String id);

  /// Tìm bài học theo loại (type).
  ///
  /// Các loại bài học: 'word', 'sentence', 'paragraph', 'conversation'.
  ///
  /// [type] - Loại bài học cần tìm.
  /// Trả về danh sách bài học thuộc loại đã chỉ định.
  @Query('SELECT * FROM lessons WHERE type = :type')
  Future<List<LessonEntity>> findLessonsByType(String type);

  /// Tìm bài học theo mức độ khó (difficulty).
  ///
  /// Các mức độ: 'beginner', 'intermediate', 'advanced'.
  ///
  /// [difficulty] - Mức độ khó cần tìm.
  /// Trả về danh sách bài học thuộc mức độ khó đã chỉ định.
  @Query('SELECT * FROM lessons WHERE difficulty = :difficulty')
  Future<List<LessonEntity>> findLessonsByDifficulty(String difficulty);

  /// Tìm bài học theo danh mục (category).
  ///
  /// Ví dụ: 'vowels', 'consonants', 'diphthongs', 'stress', 'intonation'.
  ///
  /// [category] - Danh mục bài học cần tìm.
  /// Trả về danh sách bài học thuộc danh mục đã chỉ định.
  @Query('SELECT * FROM lessons WHERE category = :category')
  Future<List<LessonEntity>> findLessonsByCategory(String category);

  /// Tìm bài học theo cả loại và mức độ khó.
  ///
  /// Kết hợp hai tiêu chí để lọc chính xác hơn.
  ///
  /// [type] - Loại bài học cần tìm.
  /// [difficulty] - Mức độ khó cần tìm.
  /// Trả về danh sách bài học khớp cả hai tiêu chí.
  @Query(
    'SELECT * FROM lessons '
    'WHERE type = :type AND difficulty = :difficulty',
  )
  Future<List<LessonEntity>> findLessonsByTypeAndDifficulty(
    String type,
    String difficulty,
  );

  /// Thêm một bài học mới vào cơ sở dữ liệu.
  ///
  /// [lesson] - Đối tượng [LessonEntity] cần thêm.
  /// Nếu trùng khóa chính sẽ bị bỏ qua (abort).
  @insert
  Future<void> insertLesson(LessonEntity lesson);

  /// Thêm nhiều bài học cùng lúc (batch insert).
  ///
  /// Sử dụng chiến lược [OnConflictStrategy.replace] để tự động
  /// thay thế bài học đã tồn tại nếu trùng khóa chính.
  /// Phù hợp cho việc đồng bộ dữ liệu bài học từ server.
  ///
  /// [lessons] - Danh sách [LessonEntity] cần thêm.
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLessons(List<LessonEntity> lessons);

  /// Cập nhật thông tin bài học đã tồn tại.
  ///
  /// [lesson] - Đối tượng [LessonEntity] với dữ liệu đã được cập nhật.
  @update
  Future<void> updateLesson(LessonEntity lesson);

  /// Xóa bài học khỏi cơ sở dữ liệu.
  ///
  /// [lesson] - Đối tượng [LessonEntity] cần xóa.
  @delete
  Future<void> deleteLesson(LessonEntity lesson);
}
