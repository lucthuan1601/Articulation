/// Widget biểu đồ cột (Bar Chart) hiển thị thời gian luyện tập 7 ngày gần nhất.
///
/// Sử dụng thư viện `fl_chart` với màu sắc từ [AppColors].
/// Mỗi cột đại diện cho một ngày, chiều cao tỉ lệ với số phút luyện tập.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/features/habit_tracking/domain/entities/practice_session.dart';

/// Biểu đồ cột hiển thị thời gian luyện tập 7 ngày gần nhất.
///
/// Dữ liệu được tự động nhóm theo ngày từ [sessions].
class WeeklyChartWidget extends StatelessWidget {
  /// Danh sách phiên luyện tập (thường là trong 7 ngày gần nhất).
  final List<PracticeSession> sessions;

  /// Mục tiêu phút mỗi ngày (hiển thị đường tham chiếu).
  final int dailyGoalMinutes;

  const WeeklyChartWidget({
    super.key,
    required this.sessions,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = _buildChartData();
    final maxY = _calculateMaxY(chartData);

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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Thời gian luyện tập',
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
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '7 ngày gần nhất',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Bar Chart ─────────────────────────────────────────
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.primary.withValues(alpha: 0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final minutes = rod.toY.toInt();
                      return BarTooltipItem(
                        '$minutes phút',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${value.toInt()}p',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                      interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 15,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            chartData[value.toInt()].label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 15,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                // Đường tham chiếu mục tiêu ngày
                extraLinesData: dailyGoalMinutes > 0
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: dailyGoalMinutes.toDouble(),
                            color: AppColors.secondary.withValues(alpha: 0.6),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              labelResolver: (_) => 'Mục tiêu',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
                barGroups: chartData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final data = entry.value;
                  final isToday = data.isToday;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: data.minutes.toDouble(),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: isToday
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.primaryLight.withValues(alpha: 0.8),
                                  AppColors.primary.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.surfaceVariant,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Legend ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.primary, 'Thời gian luyện'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.secondary, 'Mục tiêu ($dailyGoalMinutes phút)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Tạo dữ liệu biểu đồ từ [sessions] cho 7 ngày gần nhất.
  List<_DayChartData> _buildChartData() {
    final now = DateTime.now();
    final result = <_DayChartData>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      final isToday = i == 0;

      // Tính tổng phút trong ngày này
      final daySeconds = sessions
          .where((s) {
            final sessionDay =
                DateTime(s.date.year, s.date.month, s.date.day);
            return sessionDay == dayKey;
          })
          .fold<int>(0, (sum, s) => sum + s.duration.inSeconds);

      result.add(_DayChartData(
        label: isToday ? 'Hôm\nnay' : DateFormat('E', 'vi').format(day),
        minutes: daySeconds ~/ 60,
        isToday: isToday,
      ));
    }
    return result;
  }

  /// Tính maxY cho biểu đồ (tối thiểu là mục tiêu ngày * 1.3).
  double _calculateMaxY(List<_DayChartData> data) {
    final maxMinutes =
        data.fold<int>(0, (max, d) => d.minutes > max ? d.minutes : max);
    final base = maxMinutes > dailyGoalMinutes ? maxMinutes : dailyGoalMinutes;
    return (base * 1.3).ceilToDouble().clamp(30.0, double.infinity);
  }
}

/// Dữ liệu một cột trong biểu đồ.
class _DayChartData {
  final String label;
  final int minutes;
  final bool isToday;

  const _DayChartData({
    required this.label,
    required this.minutes,
    required this.isToday,
  });
}
