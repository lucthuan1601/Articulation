/// Service quản lý Push Notification cho ứng dụng Articulation.
///
/// Hỗ trợ:
/// - Lên lịch nhắc nhở luyện tập hàng ngày theo giờ tùy chọn của người dùng
/// - Thông báo chúc mừng khi đạt mốc streak
/// - Bật/tắt thông báo
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service Singleton quản lý toàn bộ Push Notification của ứng dụng.
///
/// ### Cách sử dụng:
/// ```dart
/// final ns = NotificationService();
/// await ns.initialize();
/// await ns.scheduleDailyReminder('08:00', userName: 'Minh Hiếu');
/// ```
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  /// Lấy instance Singleton.
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _dailyReminderId = 1001;
  static const int _streakAchievementId = 1002;

  // Channel IDs
  static const String _dailyChannelId = 'daily_reminder';
  static const String _achievementChannelId = 'achievements';

  bool _initialized = false;

  /// Khởi tạo notification service.
  ///
  /// Phải được gọi **một lần duy nhất** trong `main()` trước `runApp()`.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      // Khởi tạo timezone database
      tz.initializeTimeZones();
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(initSettings);
    } catch (e) {
      debugPrint('NotificationService initialize warning: $e');
    }
    _initialized = true;
  }

  /// Yêu cầu quyền hiển thị thông báo (cần thiết trên Android 13+).
  ///
  /// Trả về `true` nếu người dùng đã cấp quyền.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Lên lịch nhắc nhở luyện tập hàng ngày (lặp lại mỗi ngày).
  ///
  /// Nếu giờ đã qua trong ngày hôm nay, lịch sẽ bắt đầu từ ngày mai.
  ///
  /// [time] - Thời gian nhắc nhở theo định dạng "HH:mm" (VD: "08:00").
  /// [userName] - Tên người dùng hiển thị trong thông báo.
  Future<void> scheduleDailyReminder(
    String time, {
    String userName = 'bạn',
  }) async {
    if (kIsWeb) return;

    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(time);
    if (match == null) {
      throw FormatException('Notification time must use HH:mm format.', time);
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);

    // Hủy lịch cũ trước
    await cancelDailyReminder();

    try {
      // Tính thời điểm lên lịch
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      // Nếu giờ hôm nay đã qua, lịch sang ngày mai
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailyReminderId,
        '⏰ Đến giờ luyện phát âm rồi!',
        'Chào $userName! Chỉ 15 phút hôm nay là đủ để duy trì streak 🔥',
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChannelId,
            'Nhắc nhở luyện tập hàng ngày',
            channelDescription: 'Thông báo nhắc nhở luyện phát âm tiếng Anh',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF7C3AED),
            icon: '@mipmap/ic_launcher',
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Lặp lại mỗi ngày cùng giờ
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDailyReminder error: $e');
    }
  }

  /// Hủy thông báo nhắc nhở hàng ngày.
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(_dailyReminderId);
    } catch (_) {}
  }

  /// Hiển thị thông báo chúc mừng khi người dùng đạt mốc streak mới.
  ///
  /// [streakDays] - Số ngày streak hiện tại.
  Future<void> showStreakNotification(int streakDays) async {
    if (kIsWeb) return;
    // Chỉ thông báo ở các mốc đặc biệt
    if (!_isStreakMilestone(streakDays)) return;

    final (title, body) = _buildStreakMessage(streakDays);

    try {
      await _plugin.show(
        _streakAchievementId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _achievementChannelId,
            'Thành tích học tập',
            channelDescription: 'Thông báo khi đạt thành tích mới',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: Color(0xFFFF6B35),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  /// Kiểm tra xem [days] có phải mốc đáng thông báo không.
  bool _isStreakMilestone(int days) {
    const milestones = [3, 7, 14, 21, 30, 50, 100];
    return milestones.contains(days);
  }

  /// Tạo nội dung thông báo streak theo mốc.
  (String, String) _buildStreakMessage(int days) {
    if (days >= 100) {
      return (
        '🏆 $days ngày streak huyền thoại!',
        'Bạn đã chinh phục $days ngày không nghỉ. Đẳng cấp thực sự!'
      );
    } else if (days >= 30) {
      return (
        '🥇 $days ngày streak!',
        '$days ngày kiên trì! Bạn đang trên con đường làm chủ phát âm tiếng Anh.'
      );
    } else if (days >= 7) {
      return (
        '🔥 $days ngày streak!',
        'Hoàn thành ${days ~/ 7} tuần! Kỷ luật của bạn thật đáng nể.'
      );
    } else {
      return (
        '🔥 Streak $days ngày!',
        'Bạn đang trên đà tốt! Đừng bỏ lỡ ngày mai để duy trì streak nhé.'
      );
    }
  }

  /// Kiểm tra quyền thông báo hiện tại.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Hủy tất cả thông báo đã lên lịch.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
