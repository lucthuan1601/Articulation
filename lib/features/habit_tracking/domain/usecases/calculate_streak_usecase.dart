/// Use case tính toán và cập nhật chuỗi luyện tập (streak) của người dùng.
///
/// **Logic tính currentStreak:**
/// - Lấy tất cả ngày luyện tập (unique), sắp xếp giảm dần
/// - Nếu ngày mới nhất là hôm nay hoặc hôm qua → bắt đầu đếm streak
/// - Đếm liên tiếp cho đến khi có khoảng cách > 1 ngày
///
/// **Logic tính longestStreak:**
/// - Duyệt toàn bộ lịch sử, tìm chuỗi liên tiếp dài nhất
library;

import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';

/// Kết quả trả về từ [CalculateStreakUseCase].
class StreakResult {
  /// Chuỗi ngày luyện tập liên tiếp hiện tại.
  final int currentStreak;

  /// Chuỗi ngày luyện tập liên tiếp dài nhất trong lịch sử.
  final int longestStreak;

  /// Ngày luyện tập gần nhất (null nếu chưa từng luyện tập).
  final DateTime? lastPracticeDate;

  /// Người dùng có luyện tập hôm nay không.
  final bool practicedToday;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    this.lastPracticeDate,
    required this.practicedToday,
  });
}

/// Use case tính toán chuỗi luyện tập liên tiếp (streak).
///
/// Sử dụng [PracticeSessionRepository] để lấy lịch sử luyện tập
/// và [UserRepository] để cập nhật kết quả vào database.
class CalculateStreakUseCase {
  final PracticeSessionRepository _sessionRepository;
  final UserRepository _userRepository;

  /// Khởi tạo với các repository cần thiết.
  CalculateStreakUseCase({
    required PracticeSessionRepository sessionRepository,
    required UserRepository userRepository,
  })  : _sessionRepository = sessionRepository,
        _userRepository = userRepository;

  /// Tính toán và cập nhật streak cho người dùng có ID [userId].
  ///
  /// Trả về [StreakResult] chứa thông tin streak hiện tại và dài nhất.
  Future<StreakResult> execute(String userId) async {
    final sessions = await _sessionRepository.getSessionsByUserId(userId);
    final user = await _userRepository.getUserById(userId);

    if (sessions.isEmpty) {
      final longestStreak = user?.longestStreak ?? 0;
      final lastPracticeDate = user?.lastPracticeDate;
      if (user != null && user.currentStreak > 0 && lastPracticeDate != null) {
        await _userRepository.updateStreak(
          userId,
          0,
          longestStreak,
          lastPracticeDate,
        );
      }

      return StreakResult(
        currentStreak: 0,
        longestStreak: longestStreak,
        lastPracticeDate: lastPracticeDate,
        practicedToday: false,
      );
    }

    // Tạo danh sách ngày luyện tập duy nhất, sắp xếp giảm dần (mới → cũ)
    final practiceDays = sessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    final lastPracticeDate = practiceDays.first;
    final practicedToday = lastPracticeDate == today;

    // --- Tính currentStreak ---
    // Chỉ có streak nếu ngày gần nhất là hôm nay hoặc hôm qua
    int currentStreak = 0;
    if (lastPracticeDate == today || lastPracticeDate == yesterday) {
      currentStreak = 1;
      for (int i = 1; i < practiceDays.length; i++) {
        final diffDays = practiceDays[i - 1].difference(practiceDays[i]).inDays;
        if (diffDays == 1) {
          currentStreak++;
        } else {
          break; // Có ngày bỏ → dừng đếm
        }
      }
    }

    // --- Tính longestStreak ---
    int longestStreak = 1;
    int tempStreak = 1;
    for (int i = 1; i < practiceDays.length; i++) {
      final diffDays = practiceDays[i - 1].difference(practiceDays[i]).inDays;
      if (diffDays == 1) {
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 1;
      }
    }

    // Đảm bảo currentStreak không lớn hơn longestStreak
    if (currentStreak > longestStreak) longestStreak = currentStreak;

    // --- Cập nhật vào database ---
    if (user != null) {
      final newLongest = longestStreak > user.longestStreak
          ? longestStreak
          : user.longestStreak;
      await _userRepository.updateStreak(
        userId,
        currentStreak,
        newLongest,
        lastPracticeDate,
      );
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: user != null && user.longestStreak > longestStreak
          ? user.longestStreak
          : longestStreak,
      lastPracticeDate: lastPracticeDate,
      practicedToday: practicedToday,
    );
  }
}
