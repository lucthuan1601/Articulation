import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/di/injection.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/repositories/speech_recorder.dart';
import '../../domain/usecases/analyze_pronunciation.dart';
import '../controllers/practice_controller.dart';
import '../models/word_feedback.dart';
import '../widgets/audio_playback_button.dart';
import 'pronunciation_feedback_screen.dart';

/// Màn hình luyện đọc: hiện câu mẫu, thu âm rồi chuyển sang màn hình phản hồi.
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
    final standardAudioUrl = (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty)
        ? lesson.audioUrl
        : 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=${Uri.encodeComponent(lesson.content)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Luyện phát âm')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final state = _controller.state;
              final message = _controller.message;
              final isRecording = state == PracticeState.recording;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card bài học
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${lesson.difficulty.displayName.toUpperCase()} • ${lesson.category}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lesson.content,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lesson.ipaTranscript,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.ipaText.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lesson.vietnameseMeaning,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            AudioPlaybackButton(
                              source: standardAudioUrl,
                              label: 'Nghe mẫu bản ngữ',
                              color: AppColors.secondaryDark,
                              allowSlow: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Visualizer & Nút thu âm
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isRecording)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0, end: 1.3),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOut,
                              builder: (context, scale, child) {
                                return Container(
                                  width: 100 * scale,
                                  height: 100 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error.withValues(alpha: 0.2),
                                  ),
                                );
                              },
                            ),
                          _buildAction(state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hint(state),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isRecording ? FontWeight.bold : FontWeight.normal,
                        color: isRecording ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAction(PracticeState state) {
    if (state == PracticeState.analyzing) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: CircularProgressIndicator(strokeWidth: 4),
      );
    }
    final recording = state == PracticeState.recording;
    return IconButton.filled(
      iconSize: 48,
      tooltip: recording ? 'Dừng và chấm điểm' : 'Bắt đầu đọc',
      style: IconButton.styleFrom(
        backgroundColor: recording ? AppColors.error : AppColors.primary,
        padding: const EdgeInsets.all(16),
      ),
      onPressed: recording ? _finish : _controller.startRecording,
      icon: Icon(recording ? Icons.stop_rounded : Icons.mic_rounded),
    );
  }

  String _hint(PracticeState state) {
    switch (state) {
      case PracticeState.idle:
        return 'Chạm vào micro rồi đọc câu trên';
      case PracticeState.recording:
        return 'Đang nghe... Đọc xong thì chạm để dừng';
      case PracticeState.analyzing:
        return 'Đang phân tích âm vị AI...';
    }
  }
}
