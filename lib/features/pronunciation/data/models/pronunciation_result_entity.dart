import 'package:floor/floor.dart';

import '../../../habit_tracking/data/models/practice_session_entity.dart';
import '../../../habit_tracking/data/models/user_entity.dart';
import 'lesson_entity.dart';

/// Entity đại diện cho bảng `pronunciation_results` trong cơ sở dữ liệu.
///
/// Lưu trữ kết quả phân tích phát âm chi tiết cho mỗi bài học
/// trong một phiên luyện tập, bao gồm các thang điểm (accuracy, fluency,
/// completeness, overall) và phân tích âm vị (phoneme details).
///
/// Khóa ngoại:
/// - [sessionId] -> `practice_sessions.id`
/// - [lessonId] -> `lessons.id`
/// - [userId] -> `users.id`
@Entity(
  tableName: 'pronunciation_results',
  foreignKeys: [
    ForeignKey(
      childColumns: ['session_id'],
      parentColumns: ['id'],
      entity: PracticeSessionEntity,
      onDelete: ForeignKeyAction.cascade,
      onUpdate: ForeignKeyAction.cascade,
    ),
    ForeignKey(
      childColumns: ['lesson_id'],
      parentColumns: ['id'],
      entity: LessonEntity,
      onDelete: ForeignKeyAction.cascade,
      onUpdate: ForeignKeyAction.cascade,
    ),
    ForeignKey(
      childColumns: ['user_id'],
      parentColumns: ['id'],
      entity: UserEntity,
      onDelete: ForeignKeyAction.cascade,
      onUpdate: ForeignKeyAction.cascade,
    ),
  ],
  indices: [
    Index(value: ['session_id'], name: 'idx_pronunciation_result_session_id'),
    Index(value: ['lesson_id'], name: 'idx_pronunciation_result_lesson_id'),
    Index(value: ['user_id'], name: 'idx_pronunciation_result_user_id'),
  ],
)
class PronunciationResultEntity {
  /// Mã định danh duy nhất của kết quả phát âm (UUID)
  @PrimaryKey()
  @ColumnInfo(name: 'id')
  final String id;

  /// Mã phiên luyện tập - khóa ngoại tham chiếu đến `practice_sessions`
  @ColumnInfo(name: 'session_id')
  final String sessionId;

  /// Mã bài học - khóa ngoại tham chiếu đến `lessons`
  @ColumnInfo(name: 'lesson_id')
  final String lessonId;

  /// Mã người dùng - khóa ngoại tham chiếu đến `users`
  @ColumnInfo(name: 'user_id')
  final String userId;

  /// Đường dẫn tuyệt đối đến file ghi âm của người dùng trên thiết bị
  @ColumnInfo(name: 'audio_file_path')
  final String audioFilePath;

  /// Điểm chính xác phát âm (thang 0-100).
  /// Đánh giá mức độ chính xác từng âm so với phát âm chuẩn.
  @ColumnInfo(name: 'accuracy_score')
  final double accuracyScore;

  /// Điểm lưu loát (thang 0-100).
  /// Đánh giá tốc độ, nhịp điệu, và sự tự nhiên khi nói.
  @ColumnInfo(name: 'fluency_score')
  final double fluencyScore;

  /// Điểm đầy đủ (thang 0-100).
  /// Đánh giá mức độ hoàn chỉnh - có bỏ sót từ/âm nào không.
  @ColumnInfo(name: 'completeness_score')
  final double completenessScore;

  /// Điểm tổng hợp (thang 0-100).
  /// Kết hợp các thang điểm trên thành một đánh giá chung.
  @ColumnInfo(name: 'overall_score')
  final double overallScore;

  /// Chuỗi JSON chứa chi tiết phân tích từng âm vị (phoneme).
  /// Sử dụng [PhonemeDetail.fromJsonList] để deserialize.
  /// Ví dụ: '[{"word":"hello","status":"correct","userIpa":"həˈloʊ",...}]'
  @ColumnInfo(name: 'phoneme_details')
  final String phonemeDetails;

  /// Phản hồi và gợi ý cải thiện phát âm từ AI.
  /// Bao gồm nhận xét tổng quan và hướng dẫn luyện tập cụ thể.
  @ColumnInfo(name: 'feedback')
  final String feedback;

  /// Timestamp (milliseconds since epoch) khi kết quả được tạo
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  /// Tạo mới một [PronunciationResultEntity].
  PronunciationResultEntity({
    required this.id,
    required this.sessionId,
    required this.lessonId,
    required this.userId,
    required this.audioFilePath,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.overallScore,
    required this.phonemeDetails,
    required this.feedback,
    required this.createdAt,
  });
}
