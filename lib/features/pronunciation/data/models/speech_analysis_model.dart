import 'package:articulation/core/utils/constants.dart';

import '../../domain/entities/pronunciation_result.dart';
import '../../domain/entities/speech_analysis.dart';

/// Bóc tách JSON của `POST /api/pronunciation/analyze` thành [SpeechAnalysis].
/// Định dạng JSON được mô tả trong `ai_server/docs/ai-module.md`.
class SpeechAnalysisModel {
  SpeechAnalysisModel._();

  static const int _maxIssuesInFeedback = 2;

  static SpeechAnalysis fromJson(Map<String, dynamic> json) {
    final noisy = json['noisy'] as bool;
    return SpeechAnalysis(
      overallScore: (json['overall'] as num).toDouble(),
      accuracyScore: (json['accuracy'] as num).toDouble(),
      fluencyScore: (json['fluency'] as num).toDouble(),
      completenessScore: (json['completeness'] as num).toDouble(),
      offTarget: json['offTarget'] as bool,
      noisy: noisy,
      audioDuration: Duration(milliseconds: json['audioMs'] as int),
      feedback: _feedback(json, noisy),
      words: (json['words'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_word)
          .toList(),
    );
  }

  static String _feedback(Map<String, dynamic> json, bool noisy) {
    final verdict = json['verdict'] as Map<String, dynamic>;
    final issues = (json['issues'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .take(_maxIssuesInFeedback)
        .map((issue) => issue['title'] as String);
    return [
      verdict['message'] as String,
      if (issues.isNotEmpty) 'Cần chú ý: ${issues.join('; ')}.',
      if (noisy) 'Xung quanh hơi ồn nên điểm có thể thấp hơn thực tế.',
    ].join(' ');
  }

  static WordDetail _word(Map<String, dynamic> json) {
    return WordDetail(
      word: json['word'] as String,
      status: _wordStatus(json),
      userIpa: json['heardIpa'] as String? ?? '',
      correctIpa: json['expectedIpa'] as String,
      score: (json['score'] as num).toDouble(),
      suggestion: json['suggestion'] as String?,
      phonemes: (json['phonemes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_phoneme)
          .toList(),
    );
  }

  static String _wordStatus(Map<String, dynamic> json) {
    if (json['spoken'] != true) return AppConstants.phonemeMissed;
    return json['status'] == 'good'
        ? AppConstants.phonemeCorrect
        : AppConstants.phonemeWrong;
  }

  static PhonemeDetail _phoneme(Map<String, dynamic> json) {
    return PhonemeDetail(
      phoneme: json['expectedIpa'] as String,
      accuracyScore: (json['score'] as num).toDouble() * 100,
      assessment: _assessment(json['status'] as String),
    );
  }

  static String _assessment(String status) {
    switch (status) {
      case 'correct':
      case 'close':
        return 'correct';
      case 'missing':
        return 'omitted';
      default:
        return 'mispronounced';
    }
  }
}
