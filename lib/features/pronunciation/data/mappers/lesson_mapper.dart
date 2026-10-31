import '../../domain/entities/lesson.dart';
import '../models/lesson_entity.dart';

/// Mapper chuyển đổi giữa [LessonEntity] (tầng Data / Floor ORM)
/// và [Lesson] (tầng Domain)
class LessonMapper {
  LessonMapper._();

  /// Chuyển đổi từ [LessonEntity] sang [Lesson]
  static Lesson fromEntity(LessonEntity entity) {
    return Lesson(
      id: entity.id,
      content: entity.content,
      ipaTranscript: entity.ipaTranscript,
      vietnameseMeaning: entity.vietnameseMeaning,
      type: LessonType.fromString(entity.type),
      difficulty: DifficultyLevel.fromString(entity.difficulty),
      category: entity.category,
      audioUrl: entity.audioUrl,
      orderIndex: entity.orderIndex,
    );
  }

  /// Chuyển đổi từ [Lesson] sang [LessonEntity]
  static LessonEntity toEntity(Lesson domain) {
    return LessonEntity(
      id: domain.id,
      content: domain.content,
      ipaTranscript: domain.ipaTranscript,
      vietnameseMeaning: domain.vietnameseMeaning,
      type: domain.type.toShortString(),
      difficulty: domain.difficulty.toShortString(),
      category: domain.category,
      audioUrl: domain.audioUrl,
      orderIndex: domain.orderIndex,
    );
  }
}
