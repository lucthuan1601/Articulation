import '../../domain/entities/practice_session.dart';
import '../../domain/repositories/practice_session_repository.dart';
import '../dao/practice_session_dao.dart';
import '../mappers/practice_session_mapper.dart';

/// Implementation của [PracticeSessionRepository] sử dụng [PracticeSessionDao]
class PracticeSessionRepositoryImpl implements PracticeSessionRepository {
  final PracticeSessionDao _practiceSessionDao;

  PracticeSessionRepositoryImpl({
    required PracticeSessionDao practiceSessionDao,
  }) : _practiceSessionDao = practiceSessionDao;

  @override
  Future<List<PracticeSession>> getSessionsByUserId(String userId) async {
    final entities = await _practiceSessionDao.findSessionsByUserId(userId);
    return entities.map((e) => PracticeSessionMapper.fromEntity(e)).toList();
  }

  @override
  Future<List<PracticeSession>> getSessionsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final entities = await _practiceSessionDao.findSessionsByDateRange(
      userId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
    return entities.map((e) => PracticeSessionMapper.fromEntity(e)).toList();
  }

  @override
  Future<PracticeSession?> getTodaySession(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final entity = await _practiceSessionDao.findTodaySession(
      userId,
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    );
    if (entity == null) return null;
    return PracticeSessionMapper.fromEntity(entity);
  }

  @override
  Future<int> getTotalPracticeTime(String userId) async {
    try {
      final time = await _practiceSessionDao.getTotalPracticeTime(userId);
      return time ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<double> getAverageScore(String userId) async {
    try {
      final score = await _practiceSessionDao.getAverageScore(userId);
      return score ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Future<int> getSessionCount(String userId) async {
    try {
      final count = await _practiceSessionDao.getSessionCount(userId);
      return count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> saveSession(PracticeSession session) async {
    final entity = PracticeSessionMapper.toEntity(session);
    await _practiceSessionDao.insertSession(entity);
  }

  @override
  Future<void> updateSession(PracticeSession session) async {
    final entity = PracticeSessionMapper.toEntity(session);
    await _practiceSessionDao.updateSession(entity);
  }

  @override
  Future<void> deleteSession(String id) async {
    final entity = await _practiceSessionDao.findSessionById(id);
    if (entity != null) {
      await _practiceSessionDao.deleteSession(entity);
    }
  }
}
