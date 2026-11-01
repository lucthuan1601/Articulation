import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/features/pronunciation/presentation/models/word_feedback.dart';

/// Hiển thị câu người dùng vừa đọc, mỗi từ được tô màu theo kết quả:
/// xanh = đúng, đỏ = sai, vàng = bỏ sót. Chạm vào từ để xem gợi ý IPA.
class ColoredTranscript extends StatelessWidget {
  final List<WordFeedback> words;
  final ValueChanged<WordFeedback>? onWordTap;

  const ColoredTranscript({super.key, required this.words, this.onWordTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final w in words)
          _WordChip(
            word: w,
            onTap: onWordTap == null ? null : () => onWordTap!(w),
          ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final WordFeedback word;
  final VoidCallback? onTap;

  const _WordChip({required this.word, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = word.status;
    final radius = BorderRadius.circular(10);

    return Semantics(
      button: onTap != null,
      label: '${word.word}, ${s.label}',
      child: Material(
        color: s.background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: s.color.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              word.word,
              style: AppTextStyles.h4.copyWith(
                color: s.textColor,
                decoration: s.decoration,
                decorationStyle: s.decorationStyle,
                decorationColor: s.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chú thích màu (legend) đặt phía trên/dưới [ColoredTranscript].
class FeedbackLegend extends StatelessWidget {
  const FeedbackLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final s in WordStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.icon, size: 14, color: s.color),
              const SizedBox(width: 4),
              Text(s.label, style: AppTextStyles.bodySmall),
            ],
          ),
      ],
    );
  }
}
