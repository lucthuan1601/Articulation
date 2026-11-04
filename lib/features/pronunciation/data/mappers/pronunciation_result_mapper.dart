import 'dart:convert';

import '../../domain/entities/pronunciation_result.dart';
import '../models/phoneme_detail.dart' as data;
import '../models/pronunciation_result_entity.dart';

/// Mapper chuyển đổi giữa [PronunciationResultEntity] (tầng Data / Floor ORM)
/// và [PronunciationResult] (tầng Domain)
///
/// Cột `phoneme_details` lưu mảng theo từ (xem [data.PhonemeDetail]), mỗi từ
/// lồng danh sách âm vị của nó. Bản ghi cũ chỉ có mảng âm vị vẫn đọc được.
class PronunciationResultMapper {
  PronunciationResultMapper._();

  /// Chuyển đổi từ [PronunciationResultEntity] sang [PronunciationResult]
  static PronunciationResult fromEntity(PronunciationResultEntity entity) {
    List<PhonemeDetail> phonemes = [];
    List<WordDetail> words = [];
    if (entity.phonemeDetails.isNotEmpty) {
      try {
        final decoded = jsonDecode(entity.phonemeDetails);
        if (decoded is List) {
          final items = decoded.cast<Map<String, dynamic>>();
          if (items.isNotEmpty && items.first.containsKey('word')) {
            words = items.map(data.PhonemeDetail.fromJson).map(_toWord).toList();
            phonemes = words.expand((w) => w.phonemes).toList();
          } else {
            phonemes = items.map(PhonemeDetail.fromMap).toList();
          }
        }
      } catch (_) {
        phonemes = [];
        words = [];
      }
    }

    return PronunciationResult(
      id: entity.id,
      sessionId: entity.sessionId,
      lessonId: entity.lessonId,
      userId: entity.userId,
      audioFilePath: entity.audioFilePath,
      accuracyScore: entity.accuracyScore,
      fluencyScore: entity.fluencyScore,
      completenessScore: entity.completenessScore,
      overallScore: entity.overallScore,
      phonemeDetails: phonemes,
      words: words,
      feedback: entity.feedback,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
    );
  }

  /// Chuyển đổi từ [PronunciationResult] sang [PronunciationResultEntity]
  static PronunciationResultEntity toEntity(PronunciationResult domain) {
    final jsonString = domain.words.isNotEmpty
        ? data.PhonemeDetail.toJsonList(domain.words.map(_fromWord).toList())
        : jsonEncode(domain.phonemeDetails.map((p) => p.toMap()).toList());

    return PronunciationResultEntity(
      id: domain.id,
      sessionId: domain.sessionId,
      lessonId: domain.lessonId,
      userId: domain.userId,
      audioFilePath: domain.audioFilePath,
      accuracyScore: domain.accuracyScore,
      fluencyScore: domain.fluencyScore,
      completenessScore: domain.completenessScore,
      overallScore: domain.overallScore,
      phonemeDetails: jsonString,
      feedback: domain.feedback,
      createdAt: domain.createdAt.millisecondsSinceEpoch,
    );
  }

  static WordDetail _toWord(data.PhonemeDetail detail) {
    return WordDetail(
      word: detail.word,
      status: detail.status,
      userIpa: detail.userIpa,
      correctIpa: detail.correctIpa,
      score: detail.score,
      suggestion: detail.suggestion,
      phonemes: detail.phonemes.map(PhonemeDetail.fromMap).toList(),
    );
  }

  static data.PhonemeDetail _fromWord(WordDetail word) {
    return data.PhonemeDetail(
      word: word.word,
      status: word.status,
      userIpa: word.userIpa,
      correctIpa: word.correctIpa,
      score: word.score,
      suggestion: word.suggestion,
      phonemes: word.phonemes.map((p) => p.toMap()).toList(),
    );
  }
}
