/// Enum đại diện cho loại bài học
/// Phân loại nội dung bài học theo đơn vị ngôn ngữ
enum LessonType {
  /// Bài học từ đơn lẻ
  word,

  /// Bài học câu hoàn chỉnh
  sentence,

  /// Bài học đoạn văn
  paragraph;

  /// Chuyển đổi từ chuỗi sang enum LessonType
  /// Ném [ArgumentError] nếu giá trị không hợp lệ
  static LessonType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'word':
        return LessonType.word;
      case 'sentence':
        return LessonType.sentence;
      case 'paragraph':
        return LessonType.paragraph;
      default:
        throw ArgumentError('Loại bài học không hợp lệ: $value');
    }
  }

  /// Chuyển đổi enum sang chuỗi ngắn gọn để lưu trữ
  String toShortString() {
    switch (this) {
      case LessonType.word:
        return 'word';
      case LessonType.sentence:
        return 'sentence';
      case LessonType.paragraph:
        return 'paragraph';
    }
  }

  /// Lấy tên hiển thị tiếng Việt cho UI
  String get displayName {
    switch (this) {
      case LessonType.word:
        return 'Từ vựng';
      case LessonType.sentence:
        return 'Câu';
      case LessonType.paragraph:
        return 'Đoạn văn';
    }
  }
}

/// Enum đại diện cho mức độ khó của bài học
enum DifficultyLevel {
  /// Mức cơ bản - dành cho người mới bắt đầu
  beginner,

  /// Mức trung cấp - dành cho người đã có nền tảng
  intermediate,

  /// Mức nâng cao - dành cho người muốn hoàn thiện
  advanced;

  /// Chuyển đổi từ chuỗi sang enum DifficultyLevel
  /// Ném [ArgumentError] nếu giá trị không hợp lệ
  static DifficultyLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'advanced':
        return DifficultyLevel.advanced;
      default:
        throw ArgumentError('Mức độ khó không hợp lệ: $value');
    }
  }

  /// Chuyển đổi enum sang chuỗi ngắn gọn để lưu trữ
  String toShortString() {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'beginner';
      case DifficultyLevel.intermediate:
        return 'intermediate';
      case DifficultyLevel.advanced:
        return 'advanced';
    }
  }

  /// Lấy tên hiển thị tiếng Việt cho UI
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Cơ bản';
      case DifficultyLevel.intermediate:
        return 'Trung cấp';
      case DifficultyLevel.advanced:
        return 'Nâng cao';
    }
  }

  /// Lấy giá trị số đại diện cho mức độ khó (dùng cho sắp xếp)
  int get numericValue {
    switch (this) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.intermediate:
        return 2;
      case DifficultyLevel.advanced:
        return 3;
    }
  }
}

/// Đối tượng Lesson ở tầng Domain
/// Đại diện cho một bài học phát âm tiếng Anh
/// Chứa nội dung, phiên âm IPA, nghĩa tiếng Việt và metadata
class Lesson {
  /// ID duy nhất của bài học (UUID)
  final String id;

  /// Nội dung bài học (từ, câu hoặc đoạn văn tiếng Anh)
  final String content;

  /// Phiên âm IPA (International Phonetic Alphabet)
  final String ipaTranscript;

  /// Nghĩa tiếng Việt của nội dung bài học
  final String vietnameseMeaning;

  /// Loại bài học (từ, câu, đoạn văn)
  final LessonType type;

  /// Mức độ khó của bài học
  final DifficultyLevel difficulty;

  /// Danh mục/chủ đề bài học (ví dụ: "Greetings", "Travel", v.v.)
  final String category;

  /// URL file âm thanh mẫu (có thể null nếu chưa có)
  final String? audioUrl;

  /// Thứ tự hiển thị trong danh sách (dùng cho sắp xếp)
  final int orderIndex;

  /// Constructor với giá trị mặc định hợp lý
  const Lesson({
    required this.id,
    required this.content,
    required this.ipaTranscript,
    required this.vietnameseMeaning,
    required this.type,
    required this.difficulty,
    required this.category,
    this.audioUrl,
    this.orderIndex = 0,
  });

  /// Tạo bản sao với các trường được cập nhật
  Lesson copyWith({
    String? id,
    String? content,
    String? ipaTranscript,
    String? vietnameseMeaning,
    LessonType? type,
    DifficultyLevel? difficulty,
    String? category,
    String? audioUrl,
    int? orderIndex,
  }) {
    return Lesson(
      id: id ?? this.id,
      content: content ?? this.content,
      ipaTranscript: ipaTranscript ?? this.ipaTranscript,
      vietnameseMeaning: vietnameseMeaning ?? this.vietnameseMeaning,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      audioUrl: audioUrl ?? this.audioUrl,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  /// So sánh hai đối tượng Lesson theo giá trị
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lesson &&
        other.id == id &&
        other.content == content &&
        other.ipaTranscript == ipaTranscript &&
        other.vietnameseMeaning == vietnameseMeaning &&
        other.type == type &&
        other.difficulty == difficulty &&
        other.category == category &&
        other.audioUrl == audioUrl &&
        other.orderIndex == orderIndex;
  }

  /// Hash code dựa trên tất cả các trường
  @override
  int get hashCode {
    return Object.hash(
      id,
      content,
      ipaTranscript,
      vietnameseMeaning,
      type,
      difficulty,
      category,
      audioUrl,
      orderIndex,
    );
  }

  /// Biểu diễn chuỗi để debug
  @override
  String toString() {
    return 'Lesson('
        'id: $id, '
        'content: $content, '
        'type: ${type.toShortString()}, '
        'difficulty: ${difficulty.toShortString()}, '
        'category: $category, '
        'orderIndex: $orderIndex'
        ')';
  }
}
