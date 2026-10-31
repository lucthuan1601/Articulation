/// Đối tượng User ở tầng Domain
/// Tách biệt khỏi tầng Data (Floor Entity) để đảm bảo Clean Architecture
/// Không phụ thuộc vào bất kỳ thư viện bên ngoài nào (Floor, JSON, v.v.)
class User {
  /// ID duy nhất của người dùng (UUID)
  final String id;

  /// Tên hiển thị của người dùng
  final String name;

  /// Địa chỉ email
  final String email;

  /// URL ảnh đại diện (có thể null nếu chưa thiết lập)
  final String? avatarUrl;

  /// Mục tiêu học hàng ngày (tính bằng phút)
  final int dailyGoalMinutes;

  /// Chuỗi ngày liên tiếp hiện tại (streak)
  final int currentStreak;

  /// Chuỗi ngày liên tiếp dài nhất đạt được
  final int longestStreak;

  /// Ngày luyện tập gần nhất (null nếu chưa từng luyện tập)
  final DateTime? lastPracticeDate;

  /// Thời gian nhắc nhở hàng ngày (định dạng "HH:mm")
  final String notificationTime;

  /// Trạng thái bật/tắt thông báo nhắc nhở
  final bool isNotificationEnabled;

  /// Thời điểm tạo tài khoản
  final DateTime createdAt;

  /// Constructor với các giá trị mặc định hợp lý
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.dailyGoalMinutes = 15,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.notificationTime = '08:00',
    this.isNotificationEnabled = true,
    required this.createdAt,
  });

  /// Tạo bản sao với các trường được cập nhật
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? dailyGoalMinutes,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPracticeDate,
    String? notificationTime,
    bool? isNotificationEnabled,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      notificationTime: notificationTime ?? this.notificationTime,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// So sánh hai đối tượng User theo giá trị
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.dailyGoalMinutes == dailyGoalMinutes &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.lastPracticeDate == lastPracticeDate &&
        other.notificationTime == notificationTime &&
        other.isNotificationEnabled == isNotificationEnabled &&
        other.createdAt == createdAt;
  }

  /// Hash code dựa trên tất cả các trường
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      avatarUrl,
      dailyGoalMinutes,
      currentStreak,
      longestStreak,
      lastPracticeDate,
      notificationTime,
      isNotificationEnabled,
      createdAt,
    );
  }

  /// Biểu diễn chuỗi để debug
  @override
  String toString() {
    return 'User('
        'id: $id, '
        'name: $name, '
        'email: $email, '
        'avatarUrl: $avatarUrl, '
        'dailyGoalMinutes: $dailyGoalMinutes, '
        'currentStreak: $currentStreak, '
        'longestStreak: $longestStreak, '
        'lastPracticeDate: $lastPracticeDate, '
        'notificationTime: $notificationTime, '
        'isNotificationEnabled: $isNotificationEnabled, '
        'createdAt: $createdAt'
        ')';
  }
}
