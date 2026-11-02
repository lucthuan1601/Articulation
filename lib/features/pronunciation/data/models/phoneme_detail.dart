import 'dart:convert';

/// Model đại diện cho chi tiết phân tích phát âm của một từ/âm vị.
///
/// Đây KHÔNG phải là Floor Entity. Đây là model thuần Dart dùng để
/// serialize/deserialize dữ liệu phoneme từ/đến chuỗi JSON,
/// được lưu trữ trong cột `phoneme_details` của bảng `pronunciation_results`.
///
/// Ví dụ JSON:
/// ```json
/// {
///   "word": "hello",
///   "status": "correct",
///   "userIpa": "həˈloʊ",
///   "correctIpa": "həˈləʊ",
///   "score": 85.5,
///   "suggestion": "Chú ý phát âm nguyên âm /ə/ ở âm tiết thứ hai"
/// }
/// ```
class PhonemeDetail {
  /// Từ hoặc âm vị đang được phân tích
  final String word;

  /// Trạng thái đánh giá phát âm.
  /// Giá trị: 'correct' | 'wrong' | 'missed'
  /// - 'correct': Phát âm đúng
  /// - 'wrong': Phát âm sai
  /// - 'missed': Bỏ sót, không phát âm
  final String status;

  /// Phiên âm IPA mà người dùng thực tế phát âm
  final String userIpa;

  /// Phiên âm IPA chuẩn (native speaker)
  final String correctIpa;

  /// Điểm đánh giá cho từ/âm vị này (thang 0-100)
  final double score;

  /// Gợi ý cải thiện phát âm cho từ/âm vị cụ thể này.
  /// Null nếu phát âm đã đúng và không cần gợi ý.
  final String? suggestion;

  /// Chi tiết từng âm vị trong từ, dạng JSON của `PhonemeDetail` tầng domain.
  /// Rỗng với dữ liệu cũ chỉ có thông tin theo từ.
  final List<Map<String, dynamic>> phonemes;

  /// Tạo mới một [PhonemeDetail].
  const PhonemeDetail({
    required this.word,
    required this.status,
    required this.userIpa,
    required this.correctIpa,
    required this.score,
    this.suggestion,
    this.phonemes = const [],
  });

  /// Tạo [PhonemeDetail] từ một [Map] JSON.
  ///
  /// Ví dụ:
  /// ```dart
  /// final detail = PhonemeDetail.fromJson({
  ///   'word': 'hello',
  ///   'status': 'correct',
  ///   'userIpa': 'həˈloʊ',
  ///   'correctIpa': 'həˈləʊ',
  ///   'score': 85.5,
  ///   'suggestion': null,
  /// });
  /// ```
  factory PhonemeDetail.fromJson(Map<String, dynamic> json) {
    return PhonemeDetail(
      word: json['word'] as String,
      status: json['status'] as String,
      userIpa: json['userIpa'] as String,
      correctIpa: json['correctIpa'] as String,
      score: (json['score'] as num).toDouble(),
      suggestion: json['suggestion'] as String?,
      phonemes: (json['phonemes'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
    );
  }

  /// Chuyển đổi [PhonemeDetail] thành [Map] JSON.
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'status': status,
      'userIpa': userIpa,
      'correctIpa': correctIpa,
      'score': score,
      'suggestion': suggestion,
      'phonemes': phonemes,
    };
  }

  /// Phân tích chuỗi JSON thành danh sách [PhonemeDetail].
  ///
  /// Dùng để deserialize cột `phoneme_details` từ database.
  ///
  /// Ví dụ:
  /// ```dart
  /// final jsonString = '[{"word":"hello","status":"correct",...}]';
  /// final details = PhonemeDetail.fromJsonList(jsonString);
  /// ```
  ///
  /// Trả về danh sách rỗng nếu [jsonString] rỗng hoặc không hợp lệ.
  static List<PhonemeDetail> fromJsonList(String jsonString) {
    if (jsonString.isEmpty) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) => PhonemeDetail.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Chuyển đổi danh sách [PhonemeDetail] thành chuỗi JSON.
  ///
  /// Dùng để serialize trước khi lưu vào cột `phoneme_details` trong database.
  ///
  /// Ví dụ:
  /// ```dart
  /// final details = [PhonemeDetail(word: 'hello', ...)];
  /// final jsonString = PhonemeDetail.toJsonList(details);
  /// // Kết quả: '[{"word":"hello","status":"correct",...}]'
  /// ```
  static String toJsonList(List<PhonemeDetail> details) {
    return jsonEncode(details.map((detail) => detail.toJson()).toList());
  }

  @override
  String toString() {
    return 'PhonemeDetail(word: $word, status: $status, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhonemeDetail &&
        other.word == word &&
        other.status == status &&
        other.userIpa == userIpa &&
        other.correctIpa == correctIpa &&
        other.score == score &&
        other.suggestion == suggestion;
  }

  @override
  int get hashCode {
    return Object.hash(word, status, userIpa, correctIpa, score, suggestion);
  }
}
