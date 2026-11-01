import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/features/pronunciation/data/models/phoneme_detail.dart'
    as data;

/// Trạng thái phát âm của một từ (dùng cho tầng UI).
enum WordStatus {
  correct,
  wrong,
  missed;

  /// Chấp nhận cả giá trị của AppConstants ('correct' | 'wrong' | 'missed')
  /// lẫn giá trị của domain ('mispronounced' | 'omitted' | 'inserted').
  static WordStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'correct':
        return WordStatus.correct;
      case 'missed':
      case 'omitted':
        return WordStatus.missed;
      default:
        return WordStatus.wrong;
    }
  }
}

/// Style hiển thị cho từng trạng thái.
/// Ngoài màu còn dùng kiểu gạch chân để người mù màu vẫn phân biệt được.
extension WordStatusStyle on WordStatus {
  Color get color {
    switch (this) {
      case WordStatus.correct:
        return AppColors.success;
      case WordStatus.wrong:
        return AppColors.error;
      case WordStatus.missed:
        return AppColors.warning;
    }
  }

  /// Màu chữ đậm hơn để đủ tương phản trên nền nhạt.
  Color get textColor {
    switch (this) {
      case WordStatus.correct:
        return const Color(0xFF047857);
      case WordStatus.wrong:
        return const Color(0xFFB91C1C);
      case WordStatus.missed:
        return const Color(0xFFB45309);
    }
  }

  Color get background {
    switch (this) {
      case WordStatus.correct:
        return AppColors.successLight;
      case WordStatus.wrong:
        return AppColors.errorLight;
      case WordStatus.missed:
        return AppColors.warningLight;
    }
  }

  TextDecoration get decoration =>
      this == WordStatus.correct ? TextDecoration.none : TextDecoration.underline;

  TextDecorationStyle get decorationStyle =>
      this == WordStatus.missed
          ? TextDecorationStyle.dashed
          : TextDecorationStyle.solid;

  String get label {
    switch (this) {
      case WordStatus.correct:
        return 'Đúng';
      case WordStatus.wrong:
        return 'Sai';
      case WordStatus.missed:
        return 'Bỏ sót';
    }
  }

  IconData get icon {
    switch (this) {
      case WordStatus.correct:
        return Icons.check_circle_rounded;
      case WordStatus.wrong:
        return Icons.cancel_rounded;
      case WordStatus.missed:
        return Icons.remove_circle_rounded;
    }
  }
}

/// Dữ liệu phản hồi của MỘT từ, dành riêng cho UI.
///
/// Tách khỏi `PhonemeDetail` để UI không bị phụ thuộc khi phần logic
/// chấm điểm (Tùng/Hiếu) còn thay đổi cấu trúc.
class WordFeedback {
  final String word;
  final WordStatus status;
  final String correctIpa;
  final String userIpa;
  final double score;
  final String? suggestion;

  const WordFeedback({
    required this.word,
    required this.status,
    required this.correctIpa,
    this.userIpa = '',
    this.score = 0,
    this.suggestion,
  });

  bool get hasError => status != WordStatus.correct;

  /// Chuyển từ model JSON của tầng data (word/status/userIpa/correctIpa/...).
  factory WordFeedback.fromPhonemeDetail(data.PhonemeDetail d) {
    return WordFeedback(
      word: d.word,
      status: WordStatus.fromString(d.status),
      correctIpa: d.correctIpa,
      userIpa: d.userIpa,
      score: d.score,
      suggestion: d.suggestion,
    );
  }

  /// Parse trực tiếp chuỗi JSON lưu trong cột phonemeDetails.
  /// Trả về danh sách rỗng nếu JSON hỏng.
  static List<WordFeedback> listFromJson(String jsonString) {
    try {
      return data.PhonemeDetail.fromJsonList(jsonString)
          .map(WordFeedback.fromPhonemeDetail)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
