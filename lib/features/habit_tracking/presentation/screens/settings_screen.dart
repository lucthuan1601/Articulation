/// Màn hình cài đặt Habit Tracking.
///
/// Cho phép người dùng:
/// - Đặt mục tiêu thời gian luyện tập hàng ngày (phút)
/// - Bật/tắt thông báo nhắc nhở
/// - Chọn giờ nhận thông báo
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/features/habit_tracking/presentation/providers/habit_tracking_provider.dart';

/// Màn hình cài đặt luyện tập và thông báo.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationSettingsProvider);
    final notifNotifier = ref.read(notificationSettingsProvider.notifier);
    final goalMinutes = ref.watch(dailyGoalProvider);
    final goalNotifier = ref.read(dailyGoalProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cài đặt luyện tập',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Section: Mục tiêu hàng ngày ─────────────────────
          _SectionHeader(
            icon: Icons.flag_rounded,
            title: 'Mục tiêu luyện tập',
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thời gian mỗi ngày',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$goalMinutes phút',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primarySurface,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    valueIndicatorColor: AppColors.primary,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: goalMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11, // 5,10,15,...,60
                    label: '$goalMinutes phút',
                    onChanged: (value) {
                      goalNotifier.updateGoal(value.toInt());
                    },
                  ),
                ),
                // Quick select buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [5, 10, 15, 20, 30].map((min) {
                    final isSelected = goalMinutes == min;
                    return GestureDetector(
                      onTap: () => goalNotifier.updateGoal(min),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$min\'',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section: Thông báo ───────────────────────────────
          _SectionHeader(
            icon: Icons.notifications_rounded,
            title: 'Thông báo nhắc nhở',
          ),
          const SizedBox(height: 12),

          if (notifState.errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                notifState.errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Toggle bật/tắt
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: notifState.isEnabled
                          ? AppColors.primarySurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      notifState.isEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: notifState.isEnabled
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Bật thông báo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    notifState.isEnabled
                        ? 'Sẽ nhắc bạn lúc ${notifState.time} mỗi ngày'
                        : 'Thông báo đang tắt',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Switch(
                    value: notifState.isEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: notifState.isLoading
                        ? null
                        : (val) => notifNotifier.toggleNotification(val),
                  ),
                ),

                if (notifState.isEnabled) ...[
                  Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: AppColors.border),

                  // Chọn giờ thông báo
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Giờ nhắc nhở',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notifState.time,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint),
                      ],
                    ),
                    onTap: () async {
                      final parts = notifState.time.split(':');
                      final current = TimeOfDay(
                        hour: int.tryParse(parts[0]) ?? 8,
                        minute: int.tryParse(parts[1]) ?? 0,
                      );
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: current,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        final newTime =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        await notifNotifier.updateTime(newTime);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),



          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Header cho mỗi section trong Settings.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}


