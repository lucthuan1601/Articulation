import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../dao/lesson_dao.dart';
import '../mappers/lesson_mapper.dart';

/// Implementation của [LessonRepository] sử dụng [LessonDao]
class LessonRepositoryImpl implements LessonRepository {
  final LessonDao _lessonDao;

  LessonRepositoryImpl({required LessonDao lessonDao}) : _lessonDao = lessonDao;

  @override
  Future<List<Lesson>> getAllLessons() async {
    final entities = await _lessonDao.findAllLessons();
    return entities.map((e) => LessonMapper.fromEntity(e)).toList();
  }

  @override
  Future<Lesson?> getLessonById(String id) async {
    final entity = await _lessonDao.findLessonById(id);
    if (entity == null) return null;
    return LessonMapper.fromEntity(entity);
  }

  @override
  Future<List<Lesson>> getLessonsByType(LessonType type) async {
    final entities = await _lessonDao.findLessonsByType(type.toShortString());
    return entities.map((e) => LessonMapper.fromEntity(e)).toList();
  }

  @override
  Future<List<Lesson>> getLessonsByDifficulty(DifficultyLevel difficulty) async {
    final entities = await _lessonDao.findLessonsByDifficulty(difficulty.toShortString());
    return entities.map((e) => LessonMapper.fromEntity(e)).toList();
  }

  @override
  Future<List<Lesson>> getLessonsByCategory(String category) async {
    final entities = await _lessonDao.findLessonsByCategory(category);
    return entities.map((e) => LessonMapper.fromEntity(e)).toList();
  }

  @override
  Future<List<Lesson>> getLessonsByTypeAndDifficulty(
    LessonType type,
    DifficultyLevel difficulty,
  ) async {
    final entities = await _lessonDao.findLessonsByTypeAndDifficulty(
      type.toShortString(),
      difficulty.toShortString(),
    );
    return entities.map((e) => LessonMapper.fromEntity(e)).toList();
  }

  @override
  Future<void> saveLesson(Lesson lesson) async {
    final entity = LessonMapper.toEntity(lesson);
    await _lessonDao.insertLesson(entity);
  }

  @override
  Future<void> saveLessons(List<Lesson> lessons) async {
    final entities = lessons.map((l) => LessonMapper.toEntity(l)).toList();
    await _lessonDao.insertLessons(entities);
  }

  @override
  Future<void> deleteLesson(String id) async {
    final entity = await _lessonDao.findLessonById(id);
    if (entity != null) {
      await _lessonDao.deleteLesson(entity);
    }
  }
}
