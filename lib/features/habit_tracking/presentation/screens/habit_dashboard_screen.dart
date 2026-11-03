/// Màn hình Dashboard chính của tính năng Habit Tracking.
///
/// Hiển thị:
/// - Card streak (chuỗi ngày luyện tập liên tiếp)
/// - Biểu đồ cột thời gian 7 ngày gần nhất
/// - Heatmap lịch 90 ngày
/// - Tổng quan thống kê (tổng thời gian, điểm TB, số phiên)
///
/// Phụ trách: Nguyễn Khắc Minh Hiếu — Checklist 2 & 6
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/features/habit_tracking/presentation/providers/habit_tracking_provider.dart';
import 'package:articulation/features/habit_tracking/presentation/widgets/streak_card_widget.dart';
import 'package:articulation/features/habit_tracking/presentation/widgets/weekly_chart_widget.dart';
import 'package:articulation/features/habit_tracking/presentation/widgets/heatmap_widget.dart';
import 'package:articulation/features/habit_tracking/presentation/widgets/stats_overview_widget.dart';
import 'package:articulation/features/habit_tracking/presentation/screens/settings_screen.dart';

/// Màn hình Dashboard Habit Tracking.
///
/// Sử dụng [ConsumerWidget] để tự động rebuild khi provider thay đổi.
class HabitDashboardScreen extends ConsumerWidget {
  const HabitDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(habitStatsProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded,
                color: AppColors.streakFlame, size: 24),
            SizedBox(width: 8),
            Text(
              'Tiến độ học tập',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const _LoadingView(),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(habitStatsProvider),
        ),
        data: (stats) {
          if (stats == null) {
            return _ErrorView(
              message: 'Không tìm thấy dữ liệu người dùng.',
              onRetry: () => ref.refresh(habitStatsProvider),
            );
          }

          return streakAsync.when(
            loading: () => const _LoadingView(),
            error: (err, _) => _ErrorView(
              message: err.toString(),
              onRetry: () {
                ref.invalidate(habitStatsProvider);
                ref.invalidate(streakProvider);
              },
            ),
            data: (streak) => RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(habitStatsProvider);
                ref.invalidate(streakProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Streak Card ───────────────────────────────
                  StreakCardWidget(
                    currentStreak: streak.currentStreak,
                    longestStreak: streak.longestStreak,
                    practicedToday: streak.practicedToday,
                    todayProgress: stats.todayProgressRatio,
                    todayMinutes: stats.todayPracticeMinutes,
                    goalMinutes: stats.user.dailyGoalMinutes,
                  ),

                  const SizedBox(height: 16),

                  // ── Banner trạng thái hôm nay ─────────────────
                  if (!stats.practicedToday)
                    _TodayReminderBanner(
                      goalMinutes: stats.user.dailyGoalMinutes,
                    ),
                  if (!stats.practicedToday) const SizedBox(height: 16),

                  // ── Biểu đồ 7 ngày ───────────────────────────
                  WeeklyChartWidget(
                    sessions: stats.recentSessions,
                    dailyGoalMinutes: stats.user.dailyGoalMinutes,
                  ),

                  const SizedBox(height: 16),

                  // ── Heatmap Calendar ──────────────────────────
                  HeatmapWidget(
                    dailyPracticeSeconds: stats.dailyPracticeSeconds,
                    dailyGoalMinutes: stats.user.dailyGoalMinutes,
                  ),

                  const SizedBox(height: 16),

                  // ── Stats Overview ────────────────────────────
                  StatsOverviewWidget(
                    totalMinutes: stats.totalPracticeMinutes,
                    averageScore: stats.averageScore,
                    totalSessions: stats.totalSessions,
                    thisWeekMinutes: stats.thisWeekMinutes,
                  ),

                  const SizedBox(height: 8),

                  // ── Footer ────────────────────────────────────
                  Center(
                    child: Text(
                      'Cập nhật lần cuối: ${_formatLastUpdate(stats.recentSessions.isNotEmpty ? stats.recentSessions.first.date : null)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLastUpdate(DateTime? date) {
    if (date == null) return 'Chưa có dữ liệu';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today Reminder Banner ────────────────────────────────────────────────────

class _TodayReminderBanner extends StatelessWidget {
  final int goalMinutes;

  const _TodayReminderBanner({required this.goalMinutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bạn chưa luyện tập hôm nay! Cần $goalMinutes phút để duy trì streak.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
