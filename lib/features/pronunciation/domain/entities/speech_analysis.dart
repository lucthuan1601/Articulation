import 'pronunciation_result.dart';

/// Kết quả dịch vụ AI trả về cho một đoạn ghi âm, chưa gắn với phiên luyện tập.
class SpeechAnalysis {
  /// Điểm tổng thể (0.0 - 100.0)
  final double overallScore;

  /// Phần trăm âm đọc đúng hoàn toàn
  final double accuracyScore;

  /// Điểm lưu loát, tính từ tốc độ nói và khoảng ngừng
  final double fluencyScore;

  /// Phần trăm từ đã được đọc
  final double completenessScore;

  /// true nếu gần như đọc câu khác, không nên tính là một lần luyện tập
  final bool offTarget;

  /// true nếu nền ồn, điểm có thể thấp hơn thực tế
  final bool noisy;

  /// Thời lượng ghi âm
  final Duration audioDuration;

  /// Nhận xét tổng quan bằng tiếng Việt
  final String feedback;

  /// Kết quả theo từng từ
  final List<WordDetail> words;

  /// Constructor
  const SpeechAnalysis({
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.offTarget,
    required this.noisy,
    required this.audioDuration,
    required this.feedback,
    required this.words,
  });
}
