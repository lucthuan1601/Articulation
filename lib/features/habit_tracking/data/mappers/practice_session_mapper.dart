import '../../domain/entities/practice_session.dart';
import '../models/practice_session_entity.dart';

/// Mapper chuyển đổi giữa [PracticeSessionEntity] (tầng Data / Floor ORM)
/// và [PracticeSession] (tầng Domain)
class PracticeSessionMapper {
  PracticeSessionMapper._();

  /// Chuyển đổi từ [PracticeSessionEntity] sang [PracticeSession]
  static PracticeSession fromEntity(PracticeSessionEntity entity) {
    return PracticeSession(
      id: entity.id,
      userId: entity.userId,
      date: DateTime.fromMillisecondsSinceEpoch(entity.date),
      duration: Duration(seconds: entity.durationSeconds),
      totalScore: entity.totalScore,
      lessonsCompleted: entity.lessonsCompleted,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
    );
  }

  /// Chuyển đổi từ [PracticeSession] sang [PracticeSessionEntity]
  static PracticeSessionEntity toEntity(PracticeSession domain) {
    return PracticeSessionEntity(
      id: domain.id,
      userId: domain.userId,
      date: domain.date.millisecondsSinceEpoch,
      durationSeconds: domain.duration.inSeconds,
      totalScore: domain.totalScore,
      lessonsCompleted: domain.lessonsCompleted,
      createdAt: domain.createdAt.millisecondsSinceEpoch,
    );
  }
}
