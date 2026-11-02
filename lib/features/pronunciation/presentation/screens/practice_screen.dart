import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/di/injection.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/repositories/speech_recorder.dart';
import '../../domain/usecases/analyze_pronunciation.dart';
import '../controllers/practice_controller.dart';
import '../models/word_feedback.dart';
import 'pronunciation_feedback_screen.dart';

/// Màn hình luyện đọc: hiện câu mẫu, thu âm rồi chuyển sang màn hình phản hồi.
/// Giao diện ở mức tối thiểu để nối luồng ghi âm với phản hồi.
class PracticeScreen extends StatefulWidget {
  final Lesson lesson;
  final String userId;

  const PracticeScreen({super.key, required this.lesson, required this.userId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeController _controller = PracticeController(
    lesson: widget.lesson,
    userId: widget.userId,
    recorder: sl<SpeechRecorder>(),
    analyze: sl<AnalyzePronunciation>(),
  )..onAutoStop = _finish;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final attempt = await _controller.stopAndAnalyze();
    final result = attempt?.result;
    if (result == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PronunciationFeedbackScreen(
          lesson: widget.lesson,
          result: result,
          words: result.words
              .map((w) => WordFeedback(
                    word: w.word,
                    status: WordStatus.fromString(w.status),
                    correctIpa: w.correctIpa,
                    userIpa: w.userIpa,
                    score: w.score,
                    suggestion: w.suggestion,
                  ))
              .toList(),
          onRetry: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện phát âm')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;
          final message = _controller.message;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(lesson.content,
                    textAlign: TextAlign.center, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(lesson.ipaTranscript,
                    textAlign: TextAlign.center, style: AppTextStyles.ipaText),
                const SizedBox(height: 4),
                Text(lesson.vietnameseMeaning,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 40),
                Center(child: _buildAction(state)),
                const SizedBox(height: 16),
                Text(
                  _hint(state),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAction(PracticeState state) {
    if (state == PracticeState.analyzing) {
      return const CircularProgressIndicator();
    }
    final recording = state == PracticeState.recording;
    return IconButton.filled(
      iconSize: 48,
      tooltip: recording ? 'Dừng và chấm điểm' : 'Bắt đầu đọc',
      style: IconButton.styleFrom(
        backgroundColor: recording ? AppColors.error : AppColors.primary,
      ),
      onPressed: recording ? _finish : _controller.startRecording,
      icon: Icon(recording ? Icons.stop : Icons.mic),
    );
  }

  String _hint(PracticeState state) {
    switch (state) {
      case PracticeState.idle:
        return 'Chạm vào micro rồi đọc câu trên';
      case PracticeState.recording:
        return 'Đang nghe... Đọc xong thì chạm để dừng';
      case PracticeState.analyzing:
        return 'Đang chấm điểm...';
    }
  }
}
