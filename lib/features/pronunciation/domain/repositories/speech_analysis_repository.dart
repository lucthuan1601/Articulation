import '../entities/speech_analysis.dart';

/// Repository interface gửi đoạn ghi âm đi phân tích phát âm
abstract class SpeechAnalysisRepository {
  /// Phân tích file WAV tại [audioPath] so với câu mục tiêu [text].
  /// Ném `Failure` nếu không phân tích được.
  Future<SpeechAnalysis> analyze({
    required String audioPath,
    required String text,
  });
}
