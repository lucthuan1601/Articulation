import '../entities/pronunciation_result.dart';

/// Repository interface định nghĩa các phương thức tương tác với dữ liệu kết quả phát âm
abstract class PronunciationResultRepository {
  /// Lấy danh sách kết quả phát âm theo Session ID
  Future<List<PronunciationResult>> getResultsBySessionId(String sessionId);

  /// Lấy danh sách kết quả phát âm của một User
  Future<List<PronunciationResult>> getResultsByUserId(String userId);

  /// Lấy lịch sử phát âm cho một bài học cụ thể
  Future<List<PronunciationResult>> getResultsByLessonId(
    String userId,
    String lessonId,
  );

  /// Lấy điểm chính xác trung bình của người dùng
  Future<double> getAverageAccuracy(String userId);

  /// Lấy điểm cao nhất cho một bài học
  Future<double> getBestScoreForLesson(String userId, String lessonId);

  /// Lấy các kết quả phát âm gần đây nhất
  Future<List<PronunciationResult>> getRecentResults(
    String userId, {
    int limit = 10,
  });

  /// Lưu kết quả phát âm mới
  Future<void> saveResult(PronunciationResult result);

  /// Xóa kết quả phát âm theo ID
  Future<void> deleteResult(String id);
}
