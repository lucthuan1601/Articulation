import '../entities/practice_session.dart';

/// Repository interface định nghĩa các phương thức tương tác với dữ liệu PracticeSession
abstract class PracticeSessionRepository {
  /// Lấy danh sách phiên luyện tập của người dùng
  Future<List<PracticeSession>> getSessionsByUserId(String userId);

  /// Lấy phiên luyện tập theo khoảng thời gian (dùng cho biểu đồ thống kê)
  Future<List<PracticeSession>> getSessionsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Lấy phiên luyện tập trong ngày hôm nay
  Future<PracticeSession?> getTodaySession(String userId);

  /// Lấy tổng thời gian luyện tập (tính bằng giây)
  Future<int> getTotalPracticeTime(String userId);

  /// Lấy điểm số trung bình
  Future<double> getAverageScore(String userId);

  /// Đếm tổng số phiên luyện tập
  Future<int> getSessionCount(String userId);

  /// Lưu một phiên luyện tập mới
  Future<void> saveSession(PracticeSession session);

  /// Cập nhật phiên luyện tập
  Future<void> updateSession(PracticeSession session);

  /// Xóa phiên luyện tập theo ID
  Future<void> deleteSession(String id);
}
