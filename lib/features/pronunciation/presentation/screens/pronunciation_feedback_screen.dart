import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/features/pronunciation/domain/entities/lesson.dart';
import 'package:articulation/features/pronunciation/domain/entities/pronunciation_result.dart'
    hide PhonemeDetail;
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';
import 'package:articulation/features/pronunciation/presentation/widgets/audio_playback_button.dart';
import 'package:articulation/features/pronunciation/presentation/widgets/colored_transcript.dart';
import 'package:articulation/features/pronunciation/presentation/widgets/ipa_hint_sheet.dart';
import 'package:articulation/features/pronunciation/presentation/widgets/score_summary_card.dart';

/// Màn hình phản hồi sau khi chấm điểm phát âm (Checklist 5).
///
/// - [lesson]: bài học vừa luyện (câu mẫu, IPA chuẩn, audio mẫu)
/// - [result]: điểm số + đường dẫn file ghi âm của người dùng
/// - [words]: kết quả theo từng từ, lấy bằng
///   `WordFeedback.listFromJson(entity.phonemeDetails)`
class PronunciationFeedbackScreen extends StatelessWidget {
  final Lesson lesson;
  final PronunciationResult result;
  final List<WordFeedback> words;
  final VoidCallback? onRetry;

  const PronunciationFeedbackScreen({
    super.key,
    required this.lesson,
    required this.result,
    required this.words,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final problemWords = words.where((w) => w.hasError).toList();
    final standardAudioUrl = (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty)
        ? lesson.audioUrl
        : 'https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=${Uri.encodeComponent(lesson.content)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả phát âm')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScoreSummaryCard(
                overall: result.overallScore,
                accuracy: result.accuracyScore,
                fluency: result.fluencyScore,
                completeness: result.completenessScore,
                feedback: result.feedback,
              ),
              const SizedBox(height: 12),

              // ── Câu mẫu ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Câu mẫu', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 6),
                      Text(lesson.content, style: AppTextStyles.h4),
                      Text(lesson.ipaTranscript, style: AppTextStyles.ipaText),
                      Text(lesson.vietnameseMeaning,
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 12),
                      AudioPlaybackButton(
                        source: standardAudioUrl,
                        label: 'Nghe phát âm chuẩn',
                        color: AppColors.secondaryDark,
                        allowSlow: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Bài đọc của bạn ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bạn đã đọc', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      const FeedbackLegend(),
                      const SizedBox(height: 12),
                      ColoredTranscript(
                        words: words,
                        onWordTap: (w) => showIpaHintSheet(context, w),
                      ),
                      const SizedBox(height: 4),
                      Text('Chạm vào từ để xem gợi ý phiên âm',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 12),
                      AudioPlaybackButton(
                        source: result.audioFilePath,
                        label: 'Nghe lại bản ghi của bạn',
                      ),
                    ],
                  ),
                ),
              ),

              // ── Từ cần luyện lại ──
              if (problemWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Từ cần luyện lại (${problemWords.length})',
                            style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        for (final w in problemWords)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(w.status.icon, color: w.status.color),
                            title: Text(w.word, style: AppTextStyles.labelLarge),
                            subtitle: Text(
                              w.suggestion ?? '/${w.correctIpa}/',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => showIpaHintSheet(context, w),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.mic),
                  label: const Text('Luyện lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
