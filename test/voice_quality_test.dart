import 'package:flutter_test/flutter_test.dart';
import 'package:articulation/core/services/voice_service.dart';

void main() {
  group('VoiceService URL Generation (TTS Giọng nói bản ngữ)', () {
    test('tạo URL chuẩn cho từ tiếng Anh', () {
      final url = VoiceService.getPronunciationUrl('coffee');
      expect(url, contains('translate.google.com/translate_tts'));
      expect(url, contains('q=coffee'));
      expect(url, contains('tl=en'));
    });

    test('tạo URL chuẩn cho câu có khoảng trắng', () {
      final url = VoiceService.getPronunciationUrl('I would like a cup of coffee');
      expect(url, contains('q=I%20would%20like%20a%20cup%20of%20coffee'));
    });
  });

  group('Kiểm thử giọng người Việt (Vietnamese Learner Accent Diagnostics)', () {
    test('phát hiện lỗi /θ/ đọc thành /t/ (think -> tink)', () {
      final result = VoiceService.analyzeVietnameseLearnerMistakes(
        targetWord: 'think',
        targetIpa: 'θɪŋk',
        heardIpa: 'tɪŋk',
      );

      expect(result['isPassed'], isTrue); // Vẫn đạt ngưỡng cơ bản
      expect(result['accuracy'], 65.0);
      expect(
        (result['issues'] as List<String>).any((i) => i.contains('/θ/ thành /t/')),
        isTrue,
      );
    });

    test('phát hiện lỗi /ð/ đọc thành /d/ (this -> dis)', () {
      final result = VoiceService.analyzeVietnameseLearnerMistakes(
        targetWord: 'this',
        targetIpa: 'ðɪs',
        heardIpa: 'dɪs',
      );

      expect(result['accuracy'], 65.0);
      expect(
        (result['issues'] as List<String>).any((i) => i.contains('/ð/ thành /d/')),
        isTrue,
      );
    });

    test('phát hiện lỗi bỏ sót phụ âm cuối (like -> lai, cup -> cu)', () {
      final result = VoiceService.analyzeVietnameseLearnerMistakes(
        targetWord: 'like',
        targetIpa: 'laɪk',
        heardIpa: 'laɪ',
      );

      expect(result['accuracy'], 75.0);
      expect(
        (result['issues'] as List<String>).any((i) => i.contains('Bỏ sót phụ âm cuối')),
        isTrue,
      );
    });

    test('phát âm chuẩn thì đạt 100% không có lỗi', () {
      final result = VoiceService.analyzeVietnameseLearnerMistakes(
        targetWord: 'coffee',
        targetIpa: 'ˈkɔːfi',
        heardIpa: 'ˈkɔːfi',
      );

      expect(result['accuracy'], 100.0);
      expect(result['isPassed'], isTrue);
      expect((result['issues'] as List<String>), isEmpty);
    });
  });
}
