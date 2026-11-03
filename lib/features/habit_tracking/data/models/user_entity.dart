import 'package:floor/floor.dart';

/// Entity đại diện cho bảng `users` trong cơ sở dữ liệu.
///
/// Lưu trữ thông tin người dùng, bao gồm cài đặt mục tiêu học tập,
/// chuỗi ngày học liên tiếp (streak), và cấu hình thông báo.
@Entity(tableName: 'users')
class UserEntity {
  /// Mã người dùng - map với Firebase UID
  @PrimaryKey()
  @ColumnInfo(name: 'id')
  final String id;

  /// Tên hiển thị của người dùng
  @ColumnInfo(name: 'name')
  final String name;

  /// Địa chỉ email đăng nhập
  @ColumnInfo(name: 'email')
  final String email;

  /// URL ảnh đại diện (có thể null nếu chưa cập nhật)
  @ColumnInfo(name: 'avatar_url')
  final String? avatarUrl;

  /// Mục tiêu thời gian luyện tập mỗi ngày (đơn vị: phút)
  @ColumnInfo(name: 'daily_goal_minutes')
  final int dailyGoalMinutes;

  /// Số ngày học liên tiếp hiện tại (streak hiện tại)
  @ColumnInfo(name: 'current_streak')
  final int currentStreak;

  /// Số ngày học liên tiếp dài nhất từ trước đến nay
  @ColumnInfo(name: 'longest_streak')
  final int longestStreak;

  /// Timestamp (milliseconds since epoch) của lần luyện tập gần nhất.
  /// Null nếu người dùng chưa từng luyện tập.
  @ColumnInfo(name: 'last_practice_date')
  final int? lastPracticeDate;

  /// Khung giờ gửi thông báo nhắc nhở học tập (định dạng "HH:mm")
  @ColumnInfo(name: 'notification_time')
  final String notificationTime;

  /// Timestamp (milliseconds since epoch) khi tài khoản được tạo
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  /// Cờ bật/tắt thông báo nhắc nhở.
  /// Floor lưu dưới dạng INTEGER: 1 = bật, 0 = tắt.
  @ColumnInfo(name: 'is_notification_enabled')
  final bool isNotificationEnabled;

  /// Tạo mới một [UserEntity].
  ///
  /// Các giá trị mặc định:
  /// - [dailyGoalMinutes]: 15 phút
  /// - [currentStreak]: 0
  /// - [longestStreak]: 0
  /// - [notificationTime]: "08:00"
  /// - [isNotificationEnabled]: true (bật thông báo)
  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.dailyGoalMinutes = 15,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.notificationTime = '08:00',
    required this.createdAt,
    this.isNotificationEnabled = true,
  });
}
