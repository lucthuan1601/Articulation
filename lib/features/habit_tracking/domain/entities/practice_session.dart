/// Đối tượng PracticeSession ở tầng Domain
/// Đại diện cho một phiên luyện tập của người dùng
/// Lưu trữ thông tin về thời gian, điểm số và số bài đã hoàn thành
class PracticeSession {
  /// ID duy nhất của phiên luyện tập (UUID)
  final String id;

  /// ID của người dùng thực hiện phiên luyện tập
  final String userId;

  /// Ngày diễn ra phiên luyện tập
  final DateTime date;

  /// Thời lượng luyện tập
  final Duration duration;

  /// Tổng điểm trung bình của phiên (0.0 - 100.0)
  final double totalScore;

  /// Số bài học đã hoàn thành trong phiên
  final int lessonsCompleted;

  /// Thời điểm tạo bản ghi
  final DateTime createdAt;

  /// Constructor với giá trị mặc định hợp lý
  const PracticeSession({
    required this.id,
    required this.userId,
    required this.date,
    this.duration = Duration.zero,
    this.totalScore = 0.0,
    this.lessonsCompleted = 0,
    required this.createdAt,
  });

  /// Tạo bản sao với các trường được cập nhật
  PracticeSession copyWith({
    String? id,
    String? userId,
    DateTime? date,
    Duration? duration,
    double? totalScore,
    int? lessonsCompleted,
    DateTime? createdAt,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      totalScore: totalScore ?? this.totalScore,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// So sánh hai đối tượng PracticeSession theo giá trị
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PracticeSession &&
        other.id == id &&
        other.userId == userId &&
        other.date == date &&
        other.duration == duration &&
        other.totalScore == totalScore &&
        other.lessonsCompleted == lessonsCompleted &&
        other.createdAt == createdAt;
  }

  /// Hash code dựa trên tất cả các trường
  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      date,
      duration,
      totalScore,
      lessonsCompleted,
      createdAt,
    );
  }

  /// Biểu diễn chuỗi để debug
  @override
  String toString() {
    return 'PracticeSession('
        'id: $id, '
        'userId: $userId, '
        'date: $date, '
        'duration: $duration, '
        'totalScore: $totalScore, '
        'lessonsCompleted: $lessonsCompleted, '
        'createdAt: $createdAt'
        ')';
  }
}
