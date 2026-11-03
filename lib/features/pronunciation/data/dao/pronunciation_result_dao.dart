/// DAO (Data Access Object) cho bảng kết quả phát âm.
///
/// Cung cấp các phương thức truy vấn CRUD và các truy vấn thống kê
/// để quản lý kết quả luyện phát âm của người dùng.
///
/// Bao gồm:
/// - Truy vấn cơ bản: tìm tất cả, tìm theo ID, thêm, cập nhật, xóa
/// - Tìm kết quả theo phiên luyện tập, người dùng, bài học
/// - Thống kê: độ chính xác trung bình, điểm cao nhất
/// - Lấy kết quả gần đây nhất
library;

import 'package:floor/floor.dart';

import 'package:articulation/features/pronunciation/data/models/pronunciation_result_entity.dart';

/// DAO quản lý dữ liệu kết quả phát âm trong cơ sở dữ liệu.
///
/// Sử dụng Floor ORM để ánh xạ các truy vấn SQL sang các phương thức Dart.
/// Hỗ trợ truy vấn theo nhiều tiêu chí và thống kê hiệu suất phát âm.
@dao
abstract class PronunciationResultDao {
  /// Lấy danh sách tất cả kết quả phát âm từ cơ sở dữ liệu.
  ///
  /// Trả về [Future<List<PronunciationResultEntity>>] chứa tất cả bản ghi.
  @Query('SELECT * FROM pronunciation_results')
  Future<List<PronunciationResultEntity>> findAllResults();

  /// Tìm kết quả phát âm theo ID duy nhất.
  ///
  /// [id] - Mã định danh duy nhất của kết quả (UUID).
  /// Trả về [Future<PronunciationResultEntity?>] hoặc null nếu không tìm thấy.
  @Query('SELECT * FROM pronunciation_results WHERE id = :id')
  Future<PronunciationResultEntity?> findResultById(String id);

  /// Tìm tất cả kết quả phát âm thuộc một phiên luyện tập.
  ///
  /// [sessionId] - Mã định danh phiên luyện tập.
  /// Trả về danh sách kết quả được sắp xếp theo thời gian tạo tăng dần.
  @Query(
    'SELECT * FROM pronunciation_results '
    'WHERE session_id = :sessionId '
    'ORDER BY created_at ASC',
  )
  Future<List<PronunciationResultEntity>> findResultsBySessionId(
    String sessionId,
  );

  /// Tìm tất cả kết quả phát âm của một người dùng.
  ///
  /// [userId] - Mã định danh người dùng.
  /// Trả về danh sách kết quả được sắp xếp theo thời gian tạo giảm dần
  /// (mới nhất trước).
  @Query(
    'SELECT * FROM pronunciation_results '
    'WHERE user_id = :userId '
    'ORDER BY created_at DESC',
  )
  Future<List<PronunciationResultEntity>> findResultsByUserId(String userId);

  /// Tìm kết quả phát âm của người dùng cho một bài học cụ thể.
  ///
  /// Dùng để xem lịch sử luyện tập và tiến bộ của người dùng
  /// trên từng bài học riêng lẻ.
  ///
  /// [userId] - Mã định danh người dùng.
  /// [lessonId] - Mã định danh bài học.
  /// Trả về danh sách kết quả sắp xếp theo thời gian tạo giảm dần.
  @Query(
    'SELECT * FROM pronunciation_results '
    'WHERE user_id = :userId AND lesson_id = :lessonId '
    'ORDER BY created_at DESC',
  )
  Future<List<PronunciationResultEntity>> findResultsByLessonId(
    String userId,
    String lessonId,
  );

  /// Tính điểm chính xác trung bình (accuracy score) của người dùng.
  ///
  /// [userId] - Mã định danh người dùng.
  /// Trả về giá trị trung bình (0.0 - 100.0), hoặc null nếu chưa có kết quả.
  @Query(
    'SELECT AVG(accuracy_score) FROM pronunciation_results '
    'WHERE user_id = :userId',
  )
  Future<double?> getAverageAccuracy(String userId);

  /// Lấy điểm cao nhất (overall score) cho một bài học cụ thể.
  ///
  /// Dùng để hiển thị thành tích tốt nhất của người dùng trên từng bài học.
  ///
  /// [userId] - Mã định danh người dùng.
  /// [lessonId] - Mã định danh bài học.
  /// Trả về điểm cao nhất, hoặc null nếu chưa có kết quả cho bài học này.
  @Query(
    'SELECT MAX(overall_score) FROM pronunciation_results '
    'WHERE user_id = :userId AND lesson_id = :lessonId',
  )
  Future<double?> getBestScoreForLesson(String userId, String lessonId);

  /// Lấy các kết quả phát âm gần đây nhất của người dùng.
  ///
  /// Sắp xếp theo thời gian tạo giảm dần và giới hạn số lượng kết quả.
  /// Dùng để hiển thị hoạt động gần đây trên trang chủ hoặc dashboard.
  ///
  /// [userId] - Mã định danh người dùng.
  /// [limit] - Số lượng kết quả tối đa cần lấy.
  @Query(
    'SELECT * FROM pronunciation_results '
    'WHERE user_id = :userId '
    'ORDER BY created_at DESC '
    'LIMIT :limit',
  )
  Future<List<PronunciationResultEntity>> getRecentResults(
    String userId,
    int limit,
  );

  /// Thêm kết quả phát âm mới vào cơ sở dữ liệu.
  ///
  /// [result] - Đối tượng [PronunciationResultEntity] cần thêm.
  @insert
  Future<void> insertResult(PronunciationResultEntity result);

  /// Cập nhật thông tin kết quả phát âm đã tồn tại.
  ///
  /// [result] - Đối tượng [PronunciationResultEntity] với dữ liệu đã cập nhật.
  @update
  Future<void> updateResult(PronunciationResultEntity result);

  /// Xóa kết quả phát âm khỏi cơ sở dữ liệu.
  ///
  /// [result] - Đối tượng [PronunciationResultEntity] cần xóa.
  @delete
  Future<void> deleteResult(PronunciationResultEntity result);
}
