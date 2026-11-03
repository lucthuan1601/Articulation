import '../entities/user.dart';

/// Repository interface định nghĩa các phương thức tương tác với dữ liệu User
/// ở tầng Domain, tuân theo nguyên tắc Dependency Inversion.
abstract class UserRepository {
  /// Lấy thông tin người dùng theo ID
  Future<User?> getUserById(String id);

  /// Lấy danh sách tất cả người dùng
  Future<List<User>> getAllUsers();

  /// Thêm người dùng mới
  Future<void> saveUser(User user);

  /// Cập nhật thông tin người dùng
  Future<void> updateUser(User user);

  /// Xóa người dùng theo ID
  Future<void> deleteUser(String id);

  /// Cập nhật chuỗi luyện tập (streak)
  Future<void> updateStreak(
    String userId,
    int currentStreak,
    int longestStreak,
    DateTime lastPracticeDate,
  );

  /// Cập nhật mục tiêu thời gian luyện tập hàng ngày (phút)
  Future<void> updateDailyGoal(String userId, int minutes);

  /// Cập nhật cấu hình thông báo nhắc nhở
  Future<void> updateNotificationSettings(
    String userId,
    String time,
    bool enabled,
  );
}
