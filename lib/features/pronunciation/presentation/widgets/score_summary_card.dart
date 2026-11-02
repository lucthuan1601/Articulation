import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/core/utils/constants.dart';

/// Màu theo ngưỡng điểm: >= 80 xanh, >= 60 vàng, còn lại đỏ.
Color feedbackScoreColor(double score) {
  if (score >= AppConstants.goodScoreThreshold) return AppColors.success;
  if (score >= AppConstants.averageScoreThreshold) return AppColors.warning;
  return AppColors.error;
}

/// Thẻ tóm tắt điểm: vòng tròn điểm tổng + 3 điểm thành phần + nhận xét.
class ScoreSummaryCard extends StatelessWidget {
  final double overall;
  final double accuracy;
  final double fluency;
  final double completeness;
  final String feedback;

  const ScoreSummaryCard({
    super.key,
    required this.overall,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    this.feedback = '',
  });

  @override
  Widget build(BuildContext context) {
    final color = feedbackScoreColor(overall);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (overall / 100).clamp(0.0, 1.0),
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.border,
                        color: color,
                      ),
                      Center(
                        child: Text(
                          AppHelpers.formatScore(overall),
                          style: AppTextStyles.h2.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppHelpers.getScoreLabel(overall),
                          style: AppTextStyles.h3.copyWith(color: color)),
                      const SizedBox(height: 4),
                      Text('Điểm tổng thể', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MiniScore(label: 'Chính xác', value: accuracy),
            _MiniScore(label: 'Lưu loát', value: fluency),
            _MiniScore(label: 'Đầy đủ', value: completeness),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(feedback, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final double value;
  const _MiniScore({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = feedbackScoreColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              AppHelpers.formatScore(value),
              textAlign: TextAlign.right,
              style: AppTextStyles.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
