import 'dart:async';

import 'package:articulation/core/error/failures.dart';
import 'package:articulation/core/utils/constants.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/repositories/speech_recorder.dart';
import '../../domain/usecases/analyze_pronunciation.dart';

enum PracticeState { idle, recording, analyzing }

/// Điều khiển một lần luyện: thu âm, gửi phân tích, giữ lại lỗi để hiển thị.
class PracticeController extends ChangeNotifier {
  final Lesson lesson;
  final String userId;
  final SpeechRecorder _recorder;
  final AnalyzePronunciation _analyze;
  final Duration _maxDuration;

  PracticeState _state = PracticeState.idle;
  String? _message;
  Timer? _autoStop;
  bool _disposed = false;

  PracticeController({
    required this.lesson,
    required this.userId,
    required SpeechRecorder recorder,
    required AnalyzePronunciation analyze,
    Duration maxDuration =
        const Duration(seconds: AppConstants.maxRecordingSeconds),
  })  : _recorder = recorder,
        _analyze = analyze,
        _maxDuration = maxDuration;

  PracticeState get state => _state;

  /// Thông báo lỗi hoặc nhắc nhở cho người dùng
  String? get message => _message;

  /// Bắt đầu thu âm
  Future<void> startRecording() async {
    if (_state != PracticeState.idle) return;
    _message = null;
    _setState(PracticeState.recording);
    try {
      await _recorder.start();
      _autoStop = Timer(_maxDuration, () => onAutoStop?.call());
    } on Failure catch (failure) {
      _message = failure.message;
      _setState(PracticeState.idle);
    }
  }

  /// Được gọi khi hết thời lượng tối đa; màn hình gán để gọi [stopAndAnalyze].
  VoidCallback? onAutoStop;

  /// Dừng thu âm và phân tích. Trả về null nếu lần đọc không có kết quả để xem.
  Future<PracticeAttempt?> stopAndAnalyze() async {
    if (_state != PracticeState.recording) return null;
    _autoStop?.cancel();
    _setState(PracticeState.analyzing);

    String? path;
    try {
      path = await _recorder.stop();
      final attempt = await _analyze(
        lesson: lesson,
        userId: userId,
        audioPath: path,
      );
      if (attempt.result == null) {
        await _recorder.discard(path);
        _message = 'Có vẻ bạn đã đọc một câu khác. Hãy đọc đúng câu mẫu nhé.';
        _setState(PracticeState.idle);
        return null;
      }
      _setState(PracticeState.idle);
      return attempt;
    } on Failure catch (failure) {
      if (path != null) await _recorder.discard(path);
      _message = failure.message;
      _setState(PracticeState.idle);
      return null;
    }
  }

  void _setState(PracticeState state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoStop?.cancel();
    if (_state == PracticeState.recording) unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }
}
