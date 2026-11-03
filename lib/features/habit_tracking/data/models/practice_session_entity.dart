import 'package:floor/floor.dart';

import 'user_entity.dart';

/// Entity đại diện cho bảng `practice_sessions` trong cơ sở dữ liệu.
///
/// Mỗi phiên luyện tập ghi lại thời lượng, điểm số, và số bài học
/// mà người dùng đã hoàn thành trong một lần luyện tập.
///
/// Khóa ngoại liên kết đến bảng `users` qua [userId].
/// Có index trên cột `date` để tối ưu truy vấn theo ngày.
@Entity(
  tableName: 'practice_sessions',
  foreignKeys: [
    ForeignKey(
      childColumns: ['user_id'],
      parentColumns: ['id'],
      entity: UserEntity,
      onDelete: ForeignKeyAction.cascade,
      onUpdate: ForeignKeyAction.cascade,
    ),
  ],
  indices: [
    Index(value: ['date'], name: 'idx_practice_session_date'),
    Index(value: ['user_id'], name: 'idx_practice_session_user_id'),
  ],
)
class PracticeSessionEntity {
  /// Mã định danh duy nhất của phiên luyện tập (UUID)
  @PrimaryKey()
  @ColumnInfo(name: 'id')
  final String id;

  /// Mã người dùng - khóa ngoại tham chiếu đến bảng `users`
  @ColumnInfo(name: 'user_id')
  final String userId;

  /// Timestamp (milliseconds since epoch) đại diện cho ngày luyện tập.
  /// Có index để hỗ trợ truy vấn nhanh theo khoảng thời gian.
  @ColumnInfo(name: 'date')
  final int date;

  /// Tổng thời lượng luyện tập trong phiên (đơn vị: giây)
  @ColumnInfo(name: 'duration_seconds')
  final int durationSeconds;

  /// Điểm số trung bình của phiên luyện tập (thang 0-100)
  @ColumnInfo(name: 'total_score')
  final double totalScore;

  /// Số lượng bài học đã hoàn thành trong phiên
  @ColumnInfo(name: 'lessons_completed')
  final int lessonsCompleted;

  /// Timestamp (milliseconds since epoch) khi bản ghi được tạo
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  /// Tạo mới một [PracticeSessionEntity].
  PracticeSessionEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.durationSeconds,
    required this.totalScore,
    required this.lessonsCompleted,
    required this.createdAt,
  });
}


