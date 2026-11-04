import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Dịch vụ quản lý giọng nói và âm thanh phát âm (Checklist 7 - Lục Văn Thuận)
///
/// Hỗ trợ:
/// - Phát âm chuẩn bản ngữ cho bất kỳ từ hoặc câu tiếng Anh nào
/// - Quản lý phát lại âm thanh ghi âm người dùng trên cả Mobile và Web
/// - Thuật toán đánh giá đối chiếu âm vị (dành cho kiểm thử offline & hỗ trợ người học tiếng Việt)
class VoiceService {
  VoiceService._internal();
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get player => _audioPlayer;

  /// Tạo URL phát âm chuẩn tiếng Anh bản ngữ (US English) từ Google TTS CDN
  static String getPronunciationUrl(String text) {
    final encoded = Uri.encodeComponent(text.trim());
    return 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=$encoded';
  }

  /// Phát âm thanh từ URL hoặc file đường dẫn (hỗ trợ http, blob, filepath)
  Future<void> playAudio(String source, {double speed = 1.0}) async {
    if (source.isEmpty) return;
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      if (source.startsWith('http') || source.startsWith('blob:')) {
        await _audioPlayer.setUrl(source);
      } else {
        await _audioPlayer.setFilePath(source);
      }

      await _audioPlayer.setSpeed(speed);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('VoiceService playAudio error: $e');
    }
  }

  /// Dừng phát âm thanh
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _audioPlayer.dispose();
  }

  /// Kiểm tra các lỗi phát âm phổ biến của người Việt (Vietnamese Accent Analysis)
  /// Phục vụ kiểm thử giọng nói theo Checklist 7
  static Map<String, dynamic> analyzeVietnameseLearnerMistakes({
    required String targetWord,
    required String targetIpa,
    required String heardIpa,
  }) {
    final issues = <String>[];
    double accuracy = 100.0;

    // 1. Lỗi âm xát vô thanh /θ/ (think, thank) thường bị đọc thành /t/
    if (targetIpa.contains('θ') && (heardIpa.contains('t') && !heardIpa.contains('θ'))) {
      issues.add('Lỗi phát âm /θ/ thành /t/ (lưỡi chưa đặt giữa hai răng)');
      accuracy -= 35.0;
    }

    // 2. Lỗi âm xát hữu thanh /ð/ (this, that, the) thường bị đọc thành /d/
    if (targetIpa.contains('ð') && (heardIpa.contains('d') && !heardIpa.contains('ð'))) {
      issues.add('Lỗi phát âm /ð/ thành /d/');
      accuracy -= 35.0;
    }

    // 3. Lỗi mất phụ âm cuối (Final Consonant Deletion: /s/, /z/, /t/, /d/, /k/)
    const endingConsonants = ['s', 'z', 't', 'd', 'k', 'l'];
    for (final c in endingConsonants) {
      if (targetIpa.endsWith(c) && !heardIpa.endsWith(c)) {
        issues.add('Bỏ sót phụ âm cuối /$c/');
        accuracy -= 25.0;
        break;
      }
    }

    // 4. Lỗi nuốt nguyên âm dài /iː/, /ɔː/, /uː/ thành nguyên âm ngắn
    if (targetIpa.contains('ː') && !heardIpa.contains('ː')) {
      issues.add('Nguyên âm chưa đủ độ dài chuẩn');
      accuracy -= 15.0;
    }

    if (accuracy < 0) accuracy = 0.0;

    return {
      'targetWord': targetWord,
      'targetIpa': targetIpa,
      'heardIpa': heardIpa,
      'accuracy': accuracy,
      'issues': issues,
      'isPassed': accuracy >= 60.0,
    };
  }
}
