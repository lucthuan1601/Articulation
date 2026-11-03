/// Riverpod providers cho tính năng Habit Tracking.
///
/// Cung cấp state management cho:
/// - [habitStatsProvider] - Dữ liệu thống kê Dashboard
/// - [streakProvider] - Kết quả tính streak
/// - [notificationSettingsProvider] - Cài đặt thông báo
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:articulation/core/notifications/notification_service.dart';
import 'package:articulation/features/habit_tracking/domain/usecases/calculate_streak_usecase.dart';
import 'package:articulation/features/habit_tracking/domain/usecases/get_habit_stats_usecase.dart';
import 'package:articulation/features/habit_tracking/domain/entities/user.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';

/// ID người dùng mặc định (offline mode).
const String kDefaultUserId = 'local_user';

// ─── Providers chính ────────────────────────────────────────────────────────

/// Provider tải toàn bộ thống kê Dashboard.
///
/// `autoDispose` để giải phóng bộ nhớ khi không còn listener.
final habitStatsProvider = FutureProvider.autoDispose<HabitStats?>((ref) async {
  final useCase = GetIt.instance<GetHabitStatsUseCase>();
  return useCase.execute(kDefaultUserId);
});

/// Provider tính toán và cập nhật streak.
///
/// Thường được gọi sau khi người dùng hoàn thành một phiên luyện tập.
final streakProvider = FutureProvider.autoDispose<StreakResult>((ref) async {
  final useCase = GetIt.instance<CalculateStreakUseCase>();
  final userRepository = GetIt.instance<UserRepository>();
  final user = await userRepository.getUserById(kDefaultUserId);
  final result = await useCase.execute(kDefaultUserId);
  if (user?.isNotificationEnabled == true &&
      result.practicedToday &&
      result.currentStreak > (user?.currentStreak ?? 0)) {
    await GetIt.instance<NotificationService>()
        .showStreakNotification(result.currentStreak);
  }
  return result;
});

/// Provider thông tin người dùng hiện tại.
final currentUserProvider = FutureProvider.autoDispose<User?>((ref) async {
  final repo = GetIt.instance<UserRepository>();
  return repo.getUserById(kDefaultUserId);
});

// ─── Notification Settings Notifier ─────────────────────────────────────────

/// State cho cài đặt thông báo.
class NotificationSettingsState {
  final bool isEnabled;
  final String time;
  final bool isLoading;
  final String? errorMessage;

  const NotificationSettingsState({
    this.isEnabled = true,
    this.time = '08:00',
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationSettingsState copyWith({
    bool? isEnabled,
    String? time,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier quản lý cài đặt thông báo và đồng bộ với database.
class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  final UserRepository _userRepository;
  final NotificationService _notificationService;

  NotificationSettingsNotifier(this._userRepository, this._notificationService)
      : super(const NotificationSettingsState()) {
    _loadFromDatabase();
  }

  /// Tải cài đặt từ database khi khởi tạo.
  Future<void> _loadFromDatabase() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _userRepository.getUserById(kDefaultUserId);
      if (user != null) {
        if (user.isNotificationEnabled) {
          await _notificationService.scheduleDailyReminder(
            user.notificationTime,
            userName: user.name,
          );
        }
        state = NotificationSettingsState(
          isEnabled: user.isNotificationEnabled,
          time: user.notificationTime,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải cài đặt thông báo: $error',
      );
    }
  }

  /// Bật/tắt thông báo và cập nhật database + lịch thông báo.
  Future<void> toggleNotification(bool enabled) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _userRepository.updateNotificationSettings(
        kDefaultUserId,
        state.time,
        enabled,
      );
      state = state.copyWith(isEnabled: enabled);
      if (enabled) {
        final user = await _userRepository.getUserById(kDefaultUserId);
        await _notificationService.scheduleDailyReminder(
          state.time,
          userName: user?.name ?? 'bạn',
        );
      } else {
        await _notificationService.cancelDailyReminder();
      }
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể cập nhật thông báo: $error',
      );
    }
  }

  /// Đổi giờ thông báo và cập nhật lịch.
  ///
  /// [newTime] - Định dạng "HH:mm".
  Future<void> updateTime(String newTime) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _userRepository.updateNotificationSettings(
        kDefaultUserId,
        newTime,
        state.isEnabled,
      );
      state = state.copyWith(time: newTime);
      if (state.isEnabled) {
        final user = await _userRepository.getUserById(kDefaultUserId);
        await _notificationService.scheduleDailyReminder(
          newTime,
          userName: user?.name ?? 'bạn',
        );
      }
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể cập nhật giờ nhắc nhở: $error',
      );
    }
  }
}

/// Provider cho [NotificationSettingsNotifier].
final notificationSettingsProvider = StateNotifierProvider.autoDispose<
    NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier(
    GetIt.instance<UserRepository>(),
    NotificationService(),
  );
});

// ─── Daily Goal Notifier ─────────────────────────────────────────────────────

/// Notifier quản lý mục tiêu thời gian luyện tập hàng ngày.
class DailyGoalNotifier extends StateNotifier<int> {
  final UserRepository _userRepository;

  DailyGoalNotifier(this._userRepository) : super(15) {
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final user = await _userRepository.getUserById(kDefaultUserId);
    if (user != null) state = user.dailyGoalMinutes;
  }

  /// Cập nhật mục tiêu hàng ngày (phút) vào database.
  Future<void> updateGoal(int minutes) async {
    state = minutes;
    await _userRepository.updateDailyGoal(kDefaultUserId, minutes);
  }
}

/// Provider cho mục tiêu luyện tập hàng ngày (phút).
final dailyGoalProvider =
    StateNotifierProvider.autoDispose<DailyGoalNotifier, int>((ref) {
  return DailyGoalNotifier(GetIt.instance<UserRepository>());
});
