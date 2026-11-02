import 'package:flutter_test/flutter_test.dart';
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';
import 'package:articulation/features/pronunciation/presentation/widgets/ipa_hint_sheet.dart';

void main() {
  group('WordStatus.fromString', () {
    test('map giá trị AppConstants và domain', () {
      expect(WordStatus.fromString('correct'), WordStatus.correct);
      expect(WordStatus.fromString('wrong'), WordStatus.wrong);
      expect(WordStatus.fromString('mispronounced'), WordStatus.wrong);
      expect(WordStatus.fromString('missed'), WordStatus.missed);
      expect(WordStatus.fromString('omitted'), WordStatus.missed);
    });
  });

  group('WordFeedback.listFromJson', () {
    test('parse JSON hợp lệ', () {
      const json =
          '[{"word":"hello","status":"wrong","userIpa":"həˈloʊ","correctIpa":"həˈləʊ","score":60,"suggestion":null}]';
      final list = WordFeedback.listFromJson(json);
      expect(list.length, 1);
      expect(list.first.status, WordStatus.wrong);
      expect(list.first.hasError, true);
    });

    test('JSON hỏng trả về danh sách rỗng', () {
      expect(WordFeedback.listFromJson('not json'), isEmpty);
    });
  });

  group('mismatchedIndexes', () {
    test('chỉ đánh dấu ký tự lệch, bỏ qua dấu /', () {
      // user = "/wʌd/", ký tự ʌ ở vị trí 2 là ký tự sai
      expect(mismatchedIndexes('wʊd', '/wʌd/'), {2});
    });

    test('đọc đúng hoàn toàn thì không có ký tự sai', () {
      expect(mismatchedIndexes('laɪk', '/laɪk/'), isEmpty);
    });
  });
}
