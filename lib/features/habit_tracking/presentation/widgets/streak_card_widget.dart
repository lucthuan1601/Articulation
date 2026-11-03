/// Widget hiển thị thông tin Streak (chuỗi luyện tập liên tiếp).
///
/// Bao gồm:
/// - Icon ngọn lửa với gradient màu cam
/// - Số ngày streak hiện tại (lớn, nổi bật)
/// - Kỷ lục streak dài nhất
/// - Badge "Đã luyện hôm nay" khi đã đạt mục tiêu ngày
library;

import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';

/// Card hiển thị thông tin streak của người dùng.
///
/// Hiển thị gradient màu cam/đỏ khi streak > 0,
/// và màu xám khi streak = 0 (chưa bắt đầu).
class StreakCardWidget extends StatelessWidget {
  /// Số ngày streak hiện tại.
  final int currentStreak;

  /// Kỷ lục streak dài nhất.
  final int longestStreak;

  /// Người dùng đã luyện tập hôm nay chưa.
  final bool practicedToday;

  /// Tiến độ hôm nay so với mục tiêu (0.0 → 1.0).
  final double todayProgress;

  /// Số phút đã luyện hôm nay.
  final int todayMinutes;

  /// Mục tiêu phút mỗi ngày.
  final int goalMinutes;

  const StreakCardWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.practicedToday,
    required this.todayProgress,
    required this.todayMinutes,
    required this.goalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final hasStreak = currentStreak > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: hasStreak
            ? AppColors.streakGradient
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasStreak ? AppColors.streakFlame : Colors.grey)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                // Icon ngọn lửa
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chuỗi luyện tập',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currentStreak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            'ngày',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Badge hôm nay
                if (practicedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Hôm nay ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            // ── Tiến độ hôm nay ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hôm nay: $todayMinutes / $goalMinutes phút',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(todayProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: todayProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Kỷ lục ──────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Kỷ lục: $longestStreak ngày',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!practicedToday)
                  const Text(
                    '⚠️ Chưa luyện hôm nay!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
