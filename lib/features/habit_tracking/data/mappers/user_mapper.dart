import '../../domain/entities/user.dart';
import '../models/user_entity.dart';

/// Mapper chuyển đổi giữa [UserEntity] (tầng Data / Floor ORM)
/// và [User] (tầng Domain)
class UserMapper {
  UserMapper._();

  /// Chuyển đổi từ [UserEntity] sang [User]
  static User fromEntity(UserEntity entity) {
    return User(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
      dailyGoalMinutes: entity.dailyGoalMinutes,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      lastPracticeDate: entity.lastPracticeDate != null
          ? DateTime.fromMillisecondsSinceEpoch(entity.lastPracticeDate!)
          : null,
      notificationTime: entity.notificationTime,
      isNotificationEnabled: entity.isNotificationEnabled,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
    );
  }

  /// Chuyển đổi từ [User] sang [UserEntity]
  static UserEntity toEntity(User domain) {
    return UserEntity(
      id: domain.id,
      name: domain.name,
      email: domain.email,
      avatarUrl: domain.avatarUrl,
      dailyGoalMinutes: domain.dailyGoalMinutes,
      currentStreak: domain.currentStreak,
      longestStreak: domain.longestStreak,
      lastPracticeDate: domain.lastPracticeDate?.millisecondsSinceEpoch,
      notificationTime: domain.notificationTime,
      createdAt: domain.createdAt.millisecondsSinceEpoch,
      isNotificationEnabled: domain.isNotificationEnabled,
    );
  }
}
