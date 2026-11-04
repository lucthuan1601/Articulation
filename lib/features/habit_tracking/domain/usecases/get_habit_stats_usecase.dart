/// Use case lấy toàn bộ thống kê habit tracking cho màn hình Dashboard.
///
/// Tải song song nhiều truy vấn để tối ưu thời gian chờ,
/// sau đó tổng hợp thành [HabitStats] để UI render.
library;

import 'package:articulation/features/habit_tracking/domain/entities/practice_session.dart';
import 'package:articulation/features/habit_tracking/domain/entities/user.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';

/// Dữ liệu thống kê tổng hợp cho màn hình Dashboard.
class HabitStats {
  /// Thông tin người dùng hiện tại.
  final User user;

  /// Streak hiện tại (đã được cập nhật từ CalculateStreakUseCase).
  final int currentStreak;

  /// Streak dài nhất trong lịch sử.
  final int longestStreak;

  /// Người dùng đã luyện tập hôm nay chưa.
  final bool practicedToday;

  /// Tổng số phiên luyện tập.
  final int totalSessions;

  /// Tổng thời gian luyện tập (giây).
  final int totalPracticeSeconds;

  /// Điểm trung bình toàn bộ (0.0 - 100.0).
  final double averageScore;

  /// Danh sách phiên luyện tập 90 ngày gần nhất (cho heatmap).
  final List<PracticeSession> recentSessions;

  /// Danh sách phiên luyện tập tuần này (cho biểu đồ cột).
  final List<PracticeSession> thisWeekSessions;

  /// Map ngày → tổng giây luyện tập (key dùng cho heatmap).
  ///
  /// Key: `DateTime(year, month, day)` (không có giờ/phút/giây).
  final Map<DateTime, int> dailyPracticeSeconds;

  const HabitStats({
    required this.user,
    required this.currentStreak,
    required this.longestStreak,
    required this.practicedToday,
    required this.totalSessions,
    required this.totalPracticeSeconds,
    required this.averageScore,
    required this.recentSessions,
    required this.thisWeekSessions,
    required this.dailyPracticeSeconds,
  });

  /// Tổng thời gian luyện tập tuần này (phút).
  int get thisWeekMinutes {
    final totalSec = thisWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.duration.inSeconds,
    );
    return totalSec ~/ 60;
  }

  /// Tổng thời gian luyện tập (phút).
  int get totalPracticeMinutes => totalPracticeSeconds ~/ 60;

  /// Tiến độ hôm nay so với mục tiêu (0.0 → 1.0).
  ///
  /// Dựa trên [user.dailyGoalMinutes] và thời gian đã luyện hôm nay.
  double get todayProgressRatio {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todaySeconds = dailyPracticeSeconds[todayKey] ?? 0;
    final goalSeconds = user.dailyGoalMinutes * 60;
    if (goalSeconds <= 0) return 0.0;
    return (todaySeconds / goalSeconds).clamp(0.0, 1.0);
  }

  /// Thời gian luyện tập hôm nay (phút).
  int get todayPracticeMinutes {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    return (dailyPracticeSeconds[todayKey] ?? 0) ~/ 60;
  }
}

/// Use case lấy toàn bộ thống kê habit tracking.
///
/// Dùng `Future.wait` để tải song song nhiều truy vấn database,
/// tối ưu hiệu suất so với tải tuần tự.
class GetHabitStatsUseCase {
  final PracticeSessionRepository _sessionRepository;
  final UserRepository _userRepository;

  /// Khởi tạo với các repository cần thiết.
  GetHabitStatsUseCase({
    required PracticeSessionRepository sessionRepository,
    required UserRepository userRepository,
  })  : _sessionRepository = sessionRepository,
        _userRepository = userRepository;

  /// Tải thống kê cho người dùng có ID [userId].
  ///
  /// Trả về `null` nếu không tìm thấy user.
  Future<HabitStats?> execute(String userId) async {
    final user = await _userRepository.getUserById(userId);
    if (user == null) return null;

    final now = DateTime.now();

    // Khoảng thời gian 90 ngày cho heatmap
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    // Đầu tuần hiện tại (Thứ 2)
    final weekdayOffset = now.weekday - 1; // 0 nếu là T2
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - weekdayOffset,
    );

    // Tải song song: 90 ngày + tuần này + tổng thời gian + điểm TB + tổng phiên
    final results = await Future.wait([
      _sessionRepository.getSessionsByDateRange(userId, ninetyDaysAgo, now),
      _sessionRepository.getSessionsByDateRange(userId, weekStart, now),
      _sessionRepository.getTotalPracticeTime(userId),
      _sessionRepository.getAverageScore(userId),
      _sessionRepository.getSessionCount(userId),
    ]);

    final recentSessions = results[0] as List<PracticeSession>;
    final thisWeekSessions = results[1] as List<PracticeSession>;
    final totalSeconds = (results[2] as num?)?.toInt() ?? 0;
    final avgScore = (results[3] as num?)?.toDouble() ?? 0.0;
    final totalSessions = (results[4] as num?)?.toInt() ?? 0;

    // Kiểm tra hôm nay
    final todayKey = DateTime(now.year, now.month, now.day);
    final practicedToday = recentSessions.any((s) {
      final dayKey = DateTime(s.date.year, s.date.month, s.date.day);
      return dayKey == todayKey;
    });

    // Tạo map ngày → tổng giây cho heatmap
    final dailyMap = <DateTime, int>{};
    for (final session in recentSessions) {
      final dayKey =
          DateTime(session.date.year, session.date.month, session.date.day);
      dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + session.duration.inSeconds;
    }

    return HabitStats(
      user: user,
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
      practicedToday: practicedToday,
      totalSessions: totalSessions,
      totalPracticeSeconds: totalSeconds,
      averageScore: avgScore,
      recentSessions: recentSessions,
      thisWeekSessions: thisWeekSessions,
      dailyPracticeSeconds: dailyMap,
    );
  }
}
