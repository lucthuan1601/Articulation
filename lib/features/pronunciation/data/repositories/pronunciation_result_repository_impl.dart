import '../../domain/entities/pronunciation_result.dart';
import '../../domain/repositories/pronunciation_result_repository.dart';
import '../dao/pronunciation_result_dao.dart';
import '../mappers/pronunciation_result_mapper.dart';

/// Implementation của [PronunciationResultRepository] sử dụng [PronunciationResultDao]
class PronunciationResultRepositoryImpl implements PronunciationResultRepository {
  final PronunciationResultDao _pronunciationResultDao;

  PronunciationResultRepositoryImpl({
    required PronunciationResultDao pronunciationResultDao,
  }) : _pronunciationResultDao = pronunciationResultDao;

  @override
  Future<List<PronunciationResult>> getResultsBySessionId(String sessionId) async {
    final entities = await _pronunciationResultDao.findResultsBySessionId(sessionId);
    return entities.map((e) => PronunciationResultMapper.fromEntity(e)).toList();
  }

  @override
  Future<List<PronunciationResult>> getResultsByUserId(String userId) async {
    final entities = await _pronunciationResultDao.findResultsByUserId(userId);
    return entities.map((e) => PronunciationResultMapper.fromEntity(e)).toList();
  }

  @override
  Future<List<PronunciationResult>> getResultsByLessonId(
    String userId,
    String lessonId,
  ) async {
    final entities = await _pronunciationResultDao.findResultsByLessonId(
      userId,
      lessonId,
    );
    return entities.map((e) => PronunciationResultMapper.fromEntity(e)).toList();
  }

  @override
  Future<double> getAverageAccuracy(String userId) async {
    final avg = await _pronunciationResultDao.getAverageAccuracy(userId);
    return avg ?? 0.0;
  }

  @override
  Future<double> getBestScoreForLesson(String userId, String lessonId) async {
    final best = await _pronunciationResultDao.getBestScoreForLesson(
      userId,
      lessonId,
    );
    return best ?? 0.0;
  }

  @override
  Future<List<PronunciationResult>> getRecentResults(
    String userId, {
    int limit = 10,
  }) async {
    final entities = await _pronunciationResultDao.getRecentResults(userId, limit);
    return entities.map((e) => PronunciationResultMapper.fromEntity(e)).toList();
  }

  @override
  Future<void> saveResult(PronunciationResult result) async {
    final entity = PronunciationResultMapper.toEntity(result);
    await _pronunciationResultDao.insertResult(entity);
  }

  @override
  Future<void> deleteResult(String id) async {
    final entity = await _pronunciationResultDao.findResultById(id);
    if (entity != null) {
      await _pronunciationResultDao.deleteResult(entity);
    }
  }
}
