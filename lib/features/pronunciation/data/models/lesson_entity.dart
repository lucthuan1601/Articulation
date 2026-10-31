import 'package:floor/floor.dart';

/// Entity đại diện cho bảng `lessons` trong cơ sở dữ liệu.
///
/// Mỗi bài học chứa một đoạn nội dung tiếng Anh kèm phiên âm IPA chuẩn,
/// nghĩa tiếng Việt, và các metadata phân loại (loại, độ khó, danh mục).
@Entity(tableName: 'lessons')
class LessonEntity {
  /// Mã định danh duy nhất của bài học
  @PrimaryKey()
  @ColumnInfo(name: 'id')
  final String id;

  /// Nội dung text tiếng Anh của bài học
  /// Ví dụ: "Hello world", "How are you?"
  @ColumnInfo(name: 'content')
  final String content;

  /// Phiên âm IPA chuẩn tương ứng với nội dung
  /// Ví dụ: "/həˈləʊ wɜːld/"
  @ColumnInfo(name: 'ipa_transcript')
  final String ipaTranscript;

  /// Nghĩa tiếng Việt tương ứng để người học dễ hiểu
  @ColumnInfo(name: 'vietnamese_meaning')
  final String vietnameseMeaning;

  /// Phân loại bài học theo đơn vị nội dung.
  /// Giá trị: 'word' | 'sentence' | 'paragraph'
  @ColumnInfo(name: 'type')
  final String type;

  /// Mức độ khó của bài học.
  /// Giá trị: 'beginner' | 'intermediate' | 'advanced'
  @ColumnInfo(name: 'difficulty')
  final String difficulty;

  /// Danh mục chủ đề của bài học.
  /// Giá trị: 'greeting' | 'travel' | 'business' | 'daily' | ...
  @ColumnInfo(name: 'category')
  final String category;

  /// URL file audio phát âm chuẩn (native speaker).
  /// Null nếu chưa có audio tham khảo.
  @ColumnInfo(name: 'audio_url')
  final String? audioUrl;

  /// Thứ tự hiển thị bài học trong danh sách.
  /// Dùng để sắp xếp bài học theo trình tự logic.
  @ColumnInfo(name: 'order_index')
  final int orderIndex;

  /// Tạo mới một [LessonEntity].
  LessonEntity({
    required this.id,
    required this.content,
    required this.ipaTranscript,
    required this.vietnameseMeaning,
    required this.type,
    required this.difficulty,
    required this.category,
    this.audioUrl,
    required this.orderIndex,
  });
}
