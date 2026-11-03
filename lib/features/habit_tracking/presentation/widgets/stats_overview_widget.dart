/// Widget hiển thị tổng quan thống kê học tập.
///
/// Gồm 3 thẻ con: Tổng thời gian, Điểm trung bình, Tổng số phiên.
library;

import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';

/// Card tổng quan thống kê dạng lưới 3 cột.
class StatsOverviewWidget extends StatelessWidget {
  /// Tổng thời gian luyện tập (phút).
  final int totalMinutes;

  /// Điểm trung bình (0.0 – 100.0).
  final double averageScore;

  /// Tổng số phiên luyện tập.
  final int totalSessions;

  /// Thời gian luyện tập tuần này (phút).
  final int thisWeekMinutes;

  const StatsOverviewWidget({
    super.key,
    required this.totalMinutes,
    required this.averageScore,
    required this.totalSessions,
    required this.thisWeekMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Thống kê tổng quan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── Grid 2x2 ─────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.timer_rounded,
              iconColor: AppColors.primary,
              bgColor: AppColors.primarySurface,
              label: 'Tổng thời gian',
              value: _formatMinutes(totalMinutes),
            ),
            _StatCard(
              icon: Icons.star_rounded,
              iconColor: AppColors.streakGold,
              bgColor: const Color(0xFFFFFBEB),
              label: 'Điểm trung bình',
              value: averageScore.toStringAsFixed(1),
              unit: '/ 100',
            ),
            _StatCard(
              icon: Icons.repeat_rounded,
              iconColor: AppColors.secondary,
              bgColor: AppColors.secondarySurface,
              label: 'Tổng phiên học',
              value: '$totalSessions',              unit: 'phiên',            ),
            _StatCard(
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.success,
              bgColor: AppColors.successLight,
              label: 'Tuần này',
              value: _formatMinutes(thisWeekMinutes),
            ),
          ],
        ),
      ],
    );
  }

  /// Định dạng phút thành chuỗi dễ đọc.
  ///
  /// Ví dụ: 75 → "1g 15p", 30 → "30 phút"
  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}g ${m}p' : '$h giờ';
    }
    return '$minutes phút';
  }
}

/// Thẻ con hiển thị một chỉ số thống kê.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  final String? unit;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),

          // Value + Unit
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
