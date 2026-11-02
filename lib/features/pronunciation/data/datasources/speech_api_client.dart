import 'dart:io';

import 'package:articulation/core/error/exceptions.dart';
import 'package:dio/dio.dart';

/// Gọi API của dịch vụ AI trong thư mục `ai_server/`.
class SpeechApiClient {
  static const _audioErrorCodes = {
    'BAD_AUDIO',
    'TOO_SHORT',
    'TOO_LONG',
    'TOO_LARGE',
    'NO_SPEECH',
  };

  final Dio _dio;

  SpeechApiClient({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              // Lần gọi đầu có thể phải chờ máy chủ nạp mô hình.
              receiveTimeout: const Duration(seconds: 90),
            ));

  /// Gửi file WAV và trả về JSON kết quả.
  ///
  /// Ném [AudioException] khi bản ghi không dùng được, [NetworkException] khi
  /// không kết nối được, [PronunciationException] khi máy chủ từ chối phân tích.
  Future<Map<String, dynamic>> analyze({
    required String audioPath,
    required String text,
  }) async {
    final bytes = await File(audioPath).readAsBytes();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/pronunciation/analyze',
        queryParameters: {'text': text},
        // Gửi dạng stream để Dio không chuyển dữ liệu nhị phân thành chuỗi.
        data: Stream<List<int>>.value(bytes),
        options: Options(
          contentType: 'audio/wav',
          headers: {Headers.contentLengthHeader: bytes.length},
        ),
      );
      return response.data!;
    } on DioException catch (error) {
      throw _toException(error);
    }
  }

  Exception _toException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const NetworkException(
        message: 'Không kết nối được máy chủ AI. Hãy kiểm tra máy chủ và mạng.',
      );
    }
    final body = response.data;
    final detail = body is Map<String, dynamic> ? body['error'] : null;
    if (detail is! Map<String, dynamic>) {
      return NetworkException(
        message: 'Máy chủ AI trả về lỗi không xác định.',
        statusCode: response.statusCode,
      );
    }
    final message = detail['message'] as String;
    return _audioErrorCodes.contains(detail['code'])
        ? AudioException(message: message)
        : PronunciationException(message: message);
  }
}
