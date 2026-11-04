import 'dart:collection';

/// Đối tượng chi tiết phát âm từng âm vị (phoneme)
/// Lưu trữ thông tin đánh giá cho từng âm trong bài phát âm
class PhonemeDetail {
  /// Ký tự/âm vị được đánh giá
  final String phoneme;

  /// Điểm chính xác của âm vị (0.0 - 100.0)
  final double accuracyScore;

  /// Đánh giá: "correct", "mispronounced", "omitted", "inserted"
  final String assessment;

  /// Constructor
  const PhonemeDetail({
    required this.phoneme,
    required this.accuracyScore,
    required this.assessment,
  });

  /// Kiểm tra xem âm vị có được phát âm đúng không
  bool get isCorrect => assessment == 'correct';

  /// Kiểm tra xem âm vị có bị phát âm sai không
  bool get isMispronounced => assessment == 'mispronounced';

  /// Kiểm tra xem âm vị có bị bỏ qua không
  bool get isOmitted => assessment == 'omitted';

  /// Tạo PhonemeDetail từ Map (JSON)
  factory PhonemeDetail.fromMap(Map<String, dynamic> map) {
    return PhonemeDetail(
      phoneme: map['phoneme'] as String? ?? '',
      accuracyScore: (map['accuracyScore'] as num?)?.toDouble() ?? 0.0,
      assessment: map['assessment'] as String? ?? 'mispronounced',
    );
  }

  /// Chuyển đổi sang Map (JSON) để lưu trữ
  Map<String, dynamic> toMap() {
    return {
      'phoneme': phoneme,
      'accuracyScore': accuracyScore,
      'assessment': assessment,
    };
  }

  /// Tạo bản sao với các trường được cập nhật
  PhonemeDetail copyWith({
    String? phoneme,
    double? accuracyScore,
    String? assessment,
  }) {
    return PhonemeDetail(
      phoneme: phoneme ?? this.phoneme,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      assessment: assessment ?? this.assessment,
    );
  }

  /// So sánh hai đối tượng PhonemeDetail theo giá trị
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhonemeDetail &&
        other.phoneme == phoneme &&
        other.accuracyScore == accuracyScore &&
        other.assessment == assessment;
  }

  @override
  int get hashCode => Object.hash(phoneme, accuracyScore, assessment);

  @override
  String toString() =>
      'PhonemeDetail(phoneme: $phoneme, score: $accuracyScore, assessment: $assessment)';
}

/// Kết quả đánh giá phát âm của một từ
class WordDetail {
  /// Từ được đánh giá
  final String word;

  /// Trạng thái: 'correct' | 'wrong' | 'missed'
  final String status;

  /// Phiên âm IPA mà người dùng thực tế phát âm
  final String userIpa;

  /// Phiên âm IPA chuẩn
  final String correctIpa;

  /// Điểm của từ (0.0 - 100.0)
  final double score;

  /// Gợi ý cải thiện, null nếu từ đã đọc tốt
  final String? suggestion;

  /// Chi tiết từng âm vị trong từ
  final List<PhonemeDetail> phonemes;

  /// Constructor
  const WordDetail({
    required this.word,
    required this.status,
    required this.userIpa,
    required this.correctIpa,
    required this.score,
    this.suggestion,
    this.phonemes = const [],
  });
}

/// Đối tượng PronunciationResult ở tầng Domain
/// Đại diện cho kết quả đánh giá phát âm của một bài tập
/// Chứa điểm số chi tiết và phân tích từng âm vị
class PronunciationResult {
  /// ID duy nhất của kết quả (UUID)
  final String id;

  /// ID phiên luyện tập chứa kết quả này
  final String sessionId;

  /// ID bài học được luyện tập
  final String lessonId;

  /// ID người dùng
  final String userId;

  /// Đường dẫn file ghi âm của người dùng
  final String audioFilePath;

  /// Điểm chính xác phát âm (0.0 - 100.0)
  final double accuracyScore;

  /// Điểm lưu loát (0.0 - 100.0)
  final double fluencyScore;

  /// Điểm hoàn thiện - đọc đủ nội dung (0.0 - 100.0)
  final double completenessScore;

  /// Điểm tổng thể (trung bình có trọng số) (0.0 - 100.0)
  final double overallScore;

  /// Chi tiết đánh giá từng âm vị (parsed từ JSON)
  final List<PhonemeDetail> phonemeDetails;

  /// Kết quả theo từng từ, dùng cho màn hình phản hồi
  final List<WordDetail> words;

  /// Phản hồi/nhận xét về bài phát âm
  final String feedback;

  /// Thời điểm tạo kết quả
  final DateTime createdAt;

  /// Constructor
  const PronunciationResult({
    required this.id,
    required this.sessionId,
    required this.lessonId,
    required this.userId,
    required this.audioFilePath,
    this.accuracyScore = 0.0,
    this.fluencyScore = 0.0,
    this.completenessScore = 0.0,
    this.overallScore = 0.0,
    this.phonemeDetails = const [],
    this.words = const [],
    this.feedback = '',
    required this.createdAt,
  });

  /// Lấy danh sách các âm vị phát âm sai
  /// Bao gồm cả âm bị bỏ qua (omitted) và phát âm sai (mispronounced)
  List<PhonemeDetail> get wrongPhonemes {
    return UnmodifiableListView(
      phonemeDetails.where((p) => !p.isCorrect),
    );
  }

  /// Lấy danh sách các âm vị phát âm đúng
  List<PhonemeDetail> get correctPhonemes {
    return UnmodifiableListView(
      phonemeDetails.where((p) => p.isCorrect),
    );
  }

  /// Tính phần trăm âm vị phát âm đúng
  /// Trả về 0.0 nếu không có âm vị nào được đánh giá
  double get correctPercentage {
    if (phonemeDetails.isEmpty) return 0.0;
    return (correctPhonemes.length / phonemeDetails.length) * 100.0;
  }

  /// Kiểm tra xem kết quả có đạt yêu cầu không (>= 60 điểm)
  bool get isPassed => overallScore >= 60.0;

  /// Lấy xếp hạng dựa trên điểm tổng thể
  String get grade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }

  /// Tạo bản sao với các trường được cập nhật
  PronunciationResult copyWith({
    String? id,
    String? sessionId,
    String? lessonId,
    String? userId,
    String? audioFilePath,
    double? accuracyScore,
    double? fluencyScore,
    double? completenessScore,
    double? overallScore,
    List<PhonemeDetail>? phonemeDetails,
    List<WordDetail>? words,
    String? feedback,
    DateTime? createdAt,
  }) {
    return PronunciationResult(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      completenessScore: completenessScore ?? this.completenessScore,
      overallScore: overallScore ?? this.overallScore,
      phonemeDetails: phonemeDetails ?? this.phonemeDetails,
      words: words ?? this.words,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// So sánh hai đối tượng PronunciationResult theo giá trị
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PronunciationResult &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.lessonId == lessonId &&
        other.userId == userId &&
        other.overallScore == overallScore;
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, lessonId, userId, overallScore);

  @override
  String toString() {
    return 'PronunciationResult('
        'id: $id, '
        'lessonId: $lessonId, '
        'overallScore: $overallScore, '
        'grade: $grade, '
        'correctPercentage: ${correctPercentage.toStringAsFixed(1)}%'
        ')';
  }
}
