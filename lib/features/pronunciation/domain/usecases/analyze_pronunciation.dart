import 'package:articulation/features/habit_tracking/domain/entities/practice_session.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:uuid/uuid.dart';

import '../entities/lesson.dart';
import '../entities/pronunciation_result.dart';
import '../entities/speech_analysis.dart';
import '../repositories/pronunciation_result_repository.dart';
import '../repositories/speech_analysis_repository.dart';

/// Kết quả của một lần đọc. [result] null nghĩa là lần đọc không được lưu
/// vì người dùng đọc sai câu.
class PracticeAttempt {
  final SpeechAnalysis analysis;
  final PronunciationResult? result;

  const PracticeAttempt({required this.analysis, this.result});
}

/// Phân tích một đoạn ghi âm rồi lưu kết quả vào phiên luyện tập trong ngày.
class AnalyzePronunciation {
  final SpeechAnalysisRepository _analysisRepository;
  final PronunciationResultRepository _resultRepository;
  final PracticeSessionRepository _sessionRepository;
  final Uuid _uuid;

  AnalyzePronunciation({
    required SpeechAnalysisRepository analysisRepository,
    required PronunciationResultRepository resultRepository,
    required PracticeSessionRepository sessionRepository,
    Uuid uuid = const Uuid(),
  })  : _analysisRepository = analysisRepository,
        _resultRepository = resultRepository,
        _sessionRepository = sessionRepository,
        _uuid = uuid;

  Future<PracticeAttempt> call({
    required Lesson lesson,
    required String userId,
    required String audioPath,
  }) async {
    final analysis = await _analysisRepository.analyze(
      audioPath: audioPath,
      text: lesson.content,
    );
    if (analysis.offTarget) return PracticeAttempt(analysis: analysis);

    final session = await _addToTodaySession(userId, analysis);
    final result = PronunciationResult(
      id: _uuid.v4(),
      sessionId: session.id,
      lessonId: lesson.id,
      userId: userId,
      audioFilePath: audioPath,
      accuracyScore: analysis.accuracyScore,
      fluencyScore: analysis.fluencyScore,
      completenessScore: analysis.completenessScore,
      overallScore: analysis.overallScore,
      phonemeDetails: analysis.words.expand((w) => w.phonemes).toList(),
      words: analysis.words,
      feedback: analysis.feedback,
      createdAt: DateTime.now(),
    );
    await _resultRepository.saveResult(result);
    return PracticeAttempt(analysis: analysis, result: result);
  }

  /// Mỗi ngày dùng chung một phiên: cộng dồn thời lượng, số bài và điểm trung bình.
  Future<PracticeSession> _addToTodaySession(
    String userId,
    SpeechAnalysis analysis,
  ) async {
    final today = await _sessionRepository.getTodaySession(userId);
    if (today == null) {
      final now = DateTime.now();
      final session = PracticeSession(
        id: _uuid.v4(),
        userId: userId,
        date: now,
        duration: analysis.audioDuration,
        totalScore: analysis.overallScore,
        lessonsCompleted: 1,
        createdAt: now,
      );
      await _sessionRepository.saveSession(session);
      return session;
    }

    final count = today.lessonsCompleted;
    final session = today.copyWith(
      duration: today.duration + analysis.audioDuration,
      totalScore: (today.totalScore * count + analysis.overallScore) / (count + 1),
      lessonsCompleted: count + 1,
    );
    await _sessionRepository.updateSession(session);
    return session;
  }
}
