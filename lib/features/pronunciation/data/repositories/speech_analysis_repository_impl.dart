import 'package:articulation/core/error/error.dart';

import '../../domain/entities/speech_analysis.dart';
import '../../domain/repositories/speech_analysis_repository.dart';
import '../datasources/speech_api_client.dart';
import '../models/speech_analysis_model.dart';

/// Implementation của [SpeechAnalysisRepository] gọi dịch vụ AI qua [SpeechApiClient]
class SpeechAnalysisRepositoryImpl implements SpeechAnalysisRepository {
  final SpeechApiClient _client;

  SpeechAnalysisRepositoryImpl({required SpeechApiClient client})
      : _client = client;

  @override
  Future<SpeechAnalysis> analyze({
    required String audioPath,
    required String text,
  }) async {
    try {
      final json = await _client.analyze(audioPath: audioPath, text: text);
      return SpeechAnalysisModel.fromJson(json);
    } on AudioException catch (error) {
      throw AudioFailure(message: error.message);
    } on NetworkException catch (error) {
      throw NetworkFailure(message: error.message, code: error.statusCode);
    } on PronunciationException catch (error) {
      throw PronunciationAnalysisFailure(message: error.message);
    } on TypeError {
      // Máy chủ và app lệch phiên bản định dạng JSON.
      throw const PronunciationAnalysisFailure(
        message: 'Không đọc được kết quả từ máy chủ AI.',
      );
    }
  }
}
