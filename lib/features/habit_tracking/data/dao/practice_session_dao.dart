/// DAO (Data Access Object) cho bảng phiên luyện tập.
///
/// Cung cấp các phương thức truy vấn CRUD và các truy vấn thống kê
/// để quản lý dữ liệu phiên luyện tập phát âm của người dùng.
///
/// Bao gồm:
/// - Truy vấn cơ bản: tìm tất cả, tìm theo ID, thêm, cập nhật, xóa
/// - Tìm phiên theo người dùng và khoảng thời gian
/// - Tìm phiên luyện tập hôm nay
/// - Thống kê: tổng thời gian, điểm trung bình, số lượng phiên
library;

import 'package:floor/floor.dart';

import 'package:articulation/features/habit_tracking/data/models/practice_session_entity.dart';

/// DAO quản lý dữ liệu phiên luyện tập trong cơ sở dữ liệu.
///
/// Sử dụng Floor ORM để ánh xạ các truy vấn SQL sang các phương thức Dart.
/// Hỗ trợ truy vấn theo người dùng, khoảng thời gian, và thống kê tổng hợp.
@dao
abstract class PracticeSessionDao {
  /// Lấy danh sách tất cả phiên luyện tập từ cơ sở dữ liệu.
  ///
  /// Trả về [Future<List<PracticeSessionEntity>>] chứa tất cả bản ghi.
  @Query('SELECT * FROM practice_sessions')
  Future<List<PracticeSessionEntity>> findAllSessions();

  /// Tìm phiên luyện tập theo ID duy nhất.
  ///
  /// [id] - Mã định danh duy nhất của phiên (UUID).
  /// Trả về [Future<PracticeSessionEntity?>] hoặc null nếu không tìm thấy.
  @Query('SELECT * FROM practice_sessions WHERE id = :id')
  Future<PracticeSessionEntity?> findSessionById(String id);

  /// Tìm tất cả phiên luyện tập của một người dùng.
  ///
  /// [userId] - Mã định danh người dùng.
  /// Trả về danh sách phiên luyện tập được sắp xếp theo thời gian bắt đầu
  /// giảm dần (mới nhất trước).
  @Query(
    'SELECT * FROM practice_sessions '
    'WHERE user_id = :userId '
    'ORDER BY date DESC',
  )
  Future<List<PracticeSessionEntity>> findSessionsByUserId(String userId);

  /// Tìm phiên luyện tập trong một khoảng thời gian cụ thể.
  ///
  /// Sử dụng để lọc phiên theo tuần, tháng, hoặc khoảng tùy chỉnh.
  ///
  /// [userId] - Mã định danh người dùng.
  /// [startDate] - Timestamp bắt đầu (milliseconds since epoch).
  /// [endDate] - Timestamp kết thúc (milliseconds since epoch).
  @Query(
    'SELECT * FROM practice_sessions '
    'WHERE user_id = :userId '
    'AND date >= :startDate '
    'AND date <= :endDate '
    'ORDER BY date DESC',
  )
  Future<List<PracticeSessionEntity>> findSessionsByDateRange(
    String userId,
    int startDate,
    int endDate,
  );

  /// Tìm phiên luyện tập của ngày hôm nay.
  ///
  /// Trả về phiên đầu tiên tìm được trong khoảng từ đầu ngày đến cuối ngày.
  /// Dùng để kiểm tra người dùng đã luyện tập hôm nay chưa.
  ///
  /// [userId] - Mã định danh người dùng.
  /// [todayStart] - Timestamp đầu ngày (00:00:00).
  /// [todayEnd] - Timestamp cuối ngày (23:59:59).
  @Query(
    'SELECT * FROM practice_sessions '
    'WHERE user_id = :userId '
    'AND date >= :todayStart '
    'AND date <= :todayEnd '
    'LIMIT 1',
  )
  Future<PracticeSessionEntity?> findTodaySession(
    String userId,
    int todayStart,
    int todayEnd,
  );

  /// Tính tổng thời gian luyện tập của người dùng (tính bằng giây).
  ///
  /// [userId] - Mã định danh người dùng.
  /// Trả về tổng số giây đã luyện tập, hoặc null nếu chưa có phiên nào.
  @Query(
    'SELECT SUM(duration_seconds) FROM practice_sessions '
    'WHERE user_id = :userId',
  )
  Future<int?> getTotalPracticeTime(String userId);

  /// Tính điểm trung bình của tất cả phiên luyện tập.
  ///
  /// [userId] - Mã định danh người dùng.
  /// Trả về điểm trung bình (0.0 - 100.0), hoặc null nếu chưa có phiên nào.
  @Query(
    'SELECT AVG(total_score) FROM practice_sessions '
    'WHERE user_id = :userId',
  )
  Future<double?> getAverageScore(String userId);

  /// Đếm tổng số phiên luyện tập của người dùng.
  ///
  /// [userId] - Mã định danh người dùng.
  /// Trả về số lượng phiên, hoặc null nếu chưa có phiên nào.
  @Query(
    'SELECT COUNT(*) FROM practice_sessions '
    'WHERE user_id = :userId',
  )
  Future<int?> getSessionCount(String userId);

  /// Thêm phiên luyện tập mới vào cơ sở dữ liệu.
  ///
  /// [session] - Đối tượng [PracticeSessionEntity] cần thêm.
  @insert
  Future<void> insertSession(PracticeSessionEntity session);

  /// Cập nhật thông tin phiên luyện tập đã tồn tại.
  ///
  /// [session] - Đối tượng [PracticeSessionEntity] với dữ liệu đã cập nhật.
  @update
  Future<void> updateSession(PracticeSessionEntity session);

  /// Xóa phiên luyện tập khỏi cơ sở dữ liệu.
  ///
  /// [session] - Đối tượng [PracticeSessionEntity] cần xóa.
  @delete
  Future<void> deleteSession(PracticeSessionEntity session);
}
