import 'package:intl/intl.dart';

/// Các hằng số dùng chung toàn ứng dụng
class AppConstants {
  AppConstants._();

  // ── App Info ────────────────────────────────────────────────────
  static const String appName = 'Articulation';
  static const String appVersion = '1.0.0';
  static const String dbName = 'articulation.db';
  static const int dbVersion = 1;

  // ── AI Server ───────────────────────────────────────────────────
  /// Địa chỉ dịch vụ AI. Mặc định là máy tính chủ khi chạy trên máy ảo Android.
  /// Điện thoại thật: `flutter run --dart-define=AI_SERVER_URL=http://<ip-máy-tính>:8787`
  static const String aiServerUrl = String.fromEnvironment(
    'AI_SERVER_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );

  // ── Recording ───────────────────────────────────────────────────
  /// Giới hạn của dịch vụ AI là 30 giây, dừng sớm hơn để không bị từ chối.
  static const int maxRecordingSeconds = 29;
  static const int recordingSampleRate = 16000;

  // ── Default Values ──────────────────────────────────────────────
  static const int defaultDailyGoalMinutes = 15;
  static const String defaultNotificationTime = '08:00';
  static const int maxStreakDays = 9999;

  // ── Score Thresholds ────────────────────────────────────────────
  /// Điểm >= 80: Phát âm tốt (xanh lá)
  static const double goodScoreThreshold = 80.0;
  /// Điểm >= 60: Phát âm trung bình (vàng)
  static const double averageScoreThreshold = 60.0;
  /// Điểm < 60: Cần cải thiện (đỏ)
  static const double poorScoreThreshold = 60.0;

  // ── Phoneme Status ──────────────────────────────────────────────
  static const String phonemeCorrect = 'correct';
  static const String phonemeWrong = 'wrong';
  static const String phonemeMissed = 'missed';

  // ── Lesson Types ────────────────────────────────────────────────
  static const String lessonTypeWord = 'word';
  static const String lessonTypeSentence = 'sentence';
  static const String lessonTypeParagraph = 'paragraph';

  // ── Difficulty Levels ───────────────────────────────────────────
  static const String difficultyBeginner = 'beginner';
  static const String difficultyIntermediate = 'intermediate';
  static const String difficultyAdvanced = 'advanced';

  // ── Notification ────────────────────────────────────────────────
  static const int notificationId = 1001;
  static const String notificationChannelId = 'articulation_daily_reminder';
  static const String notificationChannelName = 'Nhắc nhở luyện tập';
  static const String notificationChannelDesc =
      'Thông báo nhắc nhở luyện tập phát âm hàng ngày';

  // ── SharedPreferences Keys ──────────────────────────────────────
  static const String prefCurrentUserId = 'current_user_id';
  static const String prefIsFirstLaunch = 'is_first_launch';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
}

/// Các hàm helper dùng chung
class AppHelpers {
  AppHelpers._();

  /// Chuyển Duration thành chuỗi hiển thị: "1h 30m" hoặc "45m"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Chuyển số giây thành Duration rồi format
  static String formatSeconds(int seconds) {
    return formatDuration(Duration(seconds: seconds));
  }

  /// Format điểm số: "85.5" hoặc "85"
  static String formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(1);
  }

  /// Format ngày theo tiếng Việt: "31/10/2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format ngày giờ: "31/10/2026 07:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Format ngày dạng ngắn: "31 Th10"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM', 'vi').format(date);
  }

  /// Lấy timestamp đầu ngày (00:00:00)
  static int getStartOfDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return startOfDay.millisecondsSinceEpoch;
  }

  /// Lấy timestamp cuối ngày (23:59:59.999)
  static int getEndOfDay(DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return endOfDay.millisecondsSinceEpoch;
  }

  /// Kiểm tra 2 ngày có cùng ngày không (bỏ qua giờ phút giây)
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Kiểm tra ngày có phải hôm qua không
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Lấy màu dựa trên điểm số (dùng trong UI)
  static String getScoreLabel(double score) {
    if (score >= AppConstants.goodScoreThreshold) return 'Xuất sắc';
    if (score >= AppConstants.averageScoreThreshold) return 'Khá';
    if (score >= 40) return 'Trung bình';
    return 'Cần cải thiện';
  }

  /// Tạo UUID v4
  static String generateId() {
    // Sử dụng package uuid trong thực tế
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
