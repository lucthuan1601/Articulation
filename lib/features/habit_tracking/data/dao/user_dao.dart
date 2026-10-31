/// DAO (Data Access Object) cho bảng người dùng.
///
/// Cung cấp các phương thức truy vấn CRUD và các truy vấn tùy chỉnh
/// để quản lý thông tin người dùng trong cơ sở dữ liệu SQLite.
///
/// Bao gồm:
/// - Truy vấn cơ bản: tìm tất cả, tìm theo ID, thêm, cập nhật, xóa
/// - Cập nhật streak (chuỗi luyện tập liên tiếp)
/// - Cập nhật mục tiêu luyện tập hàng ngày
/// - Cập nhật cài đặt thông báo
library;

import 'package:floor/floor.dart';

import 'package:articulation/features/habit_tracking/data/models/user_entity.dart';

/// DAO quản lý dữ liệu người dùng trong cơ sở dữ liệu.
///
/// Sử dụng Floor ORM để ánh xạ các truy vấn SQL sang các phương thức Dart.
/// Tất cả các tên cột sử dụng snake_case theo chuẩn SQLite.
@dao
abstract class UserDao {
  /// Lấy danh sách tất cả người dùng từ cơ sở dữ liệu.
  ///
  /// Trả về [Future<List<UserEntity>>] chứa tất cả bản ghi người dùng.
  @Query('SELECT * FROM users')
  Future<List<UserEntity>> findAllUsers();

  /// Tìm người dùng theo ID duy nhất.
  ///
  /// [id] - Mã định danh duy nhất của người dùng (UUID).
  /// Trả về [Future<UserEntity?>] hoặc null nếu không tìm thấy.
  @Query('SELECT * FROM users WHERE id = :id')
  Future<UserEntity?> findUserById(String id);

  /// Thêm người dùng mới vào cơ sở dữ liệu.
  ///
  /// [user] - Đối tượng [UserEntity] cần thêm.
  /// Nếu trùng khóa chính sẽ bị bỏ qua (abort).
  @insert
  Future<void> insertUser(UserEntity user);

  /// Cập nhật thông tin người dùng đã tồn tại.
  ///
  /// [user] - Đối tượng [UserEntity] với dữ liệu đã được cập nhật.
  @update
  Future<void> updateUser(UserEntity user);

  /// Xóa người dùng khỏi cơ sở dữ liệu.
  ///
  /// [user] - Đối tượng [UserEntity] cần xóa.
  @delete
  Future<void> deleteUser(UserEntity user);

  /// Cập nhật thông tin chuỗi luyện tập (streak) của người dùng.
  ///
  /// Cập nhật đồng thời chuỗi hiện tại, chuỗi dài nhất,
  /// và ngày luyện tập cuối cùng.
  ///
  /// [id] - Mã định danh người dùng.
  /// [currentStreak] - Số ngày luyện tập liên tiếp hiện tại.
  /// [longestStreak] - Số ngày luyện tập liên tiếp dài nhất từ trước đến nay.
  /// [lastPracticeDate] - Timestamp (milliseconds) của ngày luyện tập cuối.
  @Query(
    'UPDATE users SET '
    'current_streak = :currentStreak, '
    'longest_streak = :longestStreak, '
    'last_practice_date = :lastPracticeDate '
    'WHERE id = :id',
  )
  Future<void> updateStreak(
    String id,
    int currentStreak,
    int longestStreak,
    int lastPracticeDate,
  );

  /// Cập nhật mục tiêu luyện tập hàng ngày (số phút).
  ///
  /// [id] - Mã định danh người dùng.
  /// [minutes] - Số phút mục tiêu luyện tập mỗi ngày.
  @Query('UPDATE users SET daily_goal_minutes = :minutes WHERE id = :id')
  Future<void> updateDailyGoal(String id, int minutes);

  /// Cập nhật cài đặt thông báo nhắc nhở luyện tập.
  ///
  /// [id] - Mã định danh người dùng.
  /// [time] - Thời gian nhắc nhở (định dạng "HH:mm").
  /// [enabled] - Trạng thái bật/tắt (1 = bật, 0 = tắt).
  @Query(
    'UPDATE users SET '
    'notification_time = :time, '
    'is_notification_enabled = :enabled '
    'WHERE id = :id',
  )
  Future<void> updateNotificationSettings(String id, String time, int enabled);
}
