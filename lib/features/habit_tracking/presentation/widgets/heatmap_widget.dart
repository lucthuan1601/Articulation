/// Widget Heatmap Calendar hiển thị tần suất luyện tập 90 ngày gần nhất.
///
/// Thiết kế lưới giống GitHub Contribution Graph:
/// - Mỗi ô = 1 ngày
/// - Màu đậm hơn = thời gian luyện tập nhiều hơn
/// - 5 mức màu dựa trên [AppColors.heatmapLevels]
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:articulation/core/theme/app_colors.dart';

/// Widget heatmap calendar kiểu GitHub.
///
/// Hiển thị 90 ngày gần nhất với màu sắc thể hiện cường độ luyện tập.
class HeatmapWidget extends StatelessWidget {
  /// Map từ ngày → tổng giây luyện tập.
  ///
  /// Key: `DateTime(year, month, day)` (không có giờ/phút/giây).
  final Map<DateTime, int> dailyPracticeSeconds;

  /// Mục tiêu phút mỗi ngày (dùng để tính mức màu).
  final int dailyGoalMinutes;

  const HeatmapWidget({
    super.key,
    required this.dailyPracticeSeconds,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lịch luyện tập',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '90 ngày',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Nhãn ngày trong tuần ─────────────────────────────
          Row(
            children: [
              const SizedBox(width: 2),
              ...['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )),
            ],
          ),

          const SizedBox(height: 4),

          // ── Lưới Heatmap ─────────────────────────────────────
          ...weeks.map((week) => _buildWeekRow(week)),

          const SizedBox(height: 12),

          // ── Legend ────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Ít',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
              const SizedBox(width: 4),
              ...AppColors.heatmapLevels.map((color) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
              const SizedBox(width: 4),
              const Text(
                'Nhiều',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tạo hàng 7 ô cho một tuần.
  Widget _buildWeekRow(List<DateTime?> week) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: week.map((day) {
          if (day == null) {
            return Expanded(child: Container(margin: const EdgeInsets.all(2)));
          }
          final isToday = _isToday(day);
          final isFuture = day.isAfter(DateTime.now());
          final level = isFuture ? 0 : _calculateLevel(day);
          final color = AppColors.heatmapLevels[level];

          return Expanded(
            child: Tooltip(
              message: _buildTooltip(day),
              child: Container(
                margin: const EdgeInsets.all(2),
                height: 14,
                decoration: BoxDecoration(
                  color: isFuture ? Colors.transparent : color,
                  borderRadius: BorderRadius.circular(3),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : isFuture
                          ? Border.all(
                              color: AppColors.border.withValues(alpha: 0.3))
                          : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tạo 13 tuần (91 ngày) dưới dạng list 2D.
  List<List<DateTime?>> _buildWeeks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Bắt đầu từ 90 ngày trước
    final start = today.subtract(const Duration(days: 89));

    // Căn về Thứ 2 của tuần chứa ngày start
    final startWeekday = start.weekday; // 1 = T2, 7 = CN
    final paddingDays = startWeekday - 1;
    final gridStart = start.subtract(Duration(days: paddingDays));

    final weeks = <List<DateTime?>>[];
    var current = gridStart;

    while (current.isBefore(today.add(const Duration(days: 1)))) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = current.add(Duration(days: d));
        // Ẩn ngày trước vùng 90 ngày (padding)
        if (day.isBefore(start)) {
          week.add(null);
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    return weeks;
  }

  /// Tính mức màu (0–4) dựa trên thời gian luyện tập của ngày [day].
  int _calculateLevel(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final seconds = dailyPracticeSeconds[key] ?? 0;
    if (seconds <= 0) return 0;
    final minutes = seconds / 60;
    final goal = dailyGoalMinutes > 0 ? dailyGoalMinutes : 15;
    if (minutes >= goal) return 4;
    if (minutes >= goal * 0.75) return 3;
    if (minutes >= goal * 0.5) return 2;
    return 1;
  }

  /// Kiểm tra xem [day] có phải hôm nay không.
  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  /// Tạo nội dung tooltip cho ô heatmap.
  String _buildTooltip(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final seconds = dailyPracticeSeconds[key] ?? 0;
    final dateStr = DateFormat('dd/MM/yyyy').format(day);
    if (seconds <= 0) return '$dateStr\nChưa luyện tập';
    final minutes = seconds ~/ 60;
    return '$dateStr\n$minutes phút luyện tập';
  }
}
