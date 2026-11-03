import 'dart:convert';

import '../../domain/entities/pronunciation_result.dart';
import '../models/pronunciation_result_entity.dart';

/// Mapper chuyển đổi giữa [PronunciationResultEntity] (tầng Data / Floor ORM)
/// và [PronunciationResult] (tầng Domain)
class PronunciationResultMapper {
  PronunciationResultMapper._();

  /// Chuyển đổi từ [PronunciationResultEntity] sang [PronunciationResult]
  static PronunciationResult fromEntity(PronunciationResultEntity entity) {
    List<PhonemeDetail> phonemes = [];
    if (entity.phonemeDetails.isNotEmpty) {
      try {
        final decoded = jsonDecode(entity.phonemeDetails);
        if (decoded is List) {
          phonemes = decoded
              .map((item) => PhonemeDetail.fromMap(item as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        phonemes = [];
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
      feedback: entity.feedback,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAt),
    );
  }

  /// Chuyển đổi từ [PronunciationResult] sang [PronunciationResultEntity]
  static PronunciationResultEntity toEntity(PronunciationResult domain) {
    final phonemeListMaps = domain.phonemeDetails.map((p) => p.toMap()).toList();
    final jsonString = jsonEncode(phonemeListMaps);

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
}
