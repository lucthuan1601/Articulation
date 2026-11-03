import 'package:get_it/get_it.dart';
import 'package:articulation/core/database/app_database.dart';
import 'package:articulation/core/notifications/notification_service.dart';
import 'package:articulation/features/habit_tracking/data/repositories/user_repository_impl.dart';
import 'package:articulation/features/habit_tracking/data/repositories/practice_session_repository_impl.dart';
import 'package:articulation/features/pronunciation/data/repositories/lesson_repository_impl.dart';
import 'package:articulation/features/pronunciation/data/repositories/pronunciation_result_repository_impl.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/lesson_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/pronunciation_result_repository.dart';
import 'package:articulation/features/habit_tracking/domain/usecases/calculate_streak_usecase.dart';
import 'package:articulation/features/habit_tracking/domain/usecases/get_habit_stats_usecase.dart';

/// Service Locator sử dụng GetIt
/// Đăng ký tất cả dependencies của ứng dụng
final GetIt sl = GetIt.instance;

/// Khởi tạo tất cả dependencies
/// Được gọi trong main() trước khi runApp()
Future<void> initDependencies() async {
  // ══════════════════════════════════════════════════════════════
  // DATABASE
  // ══════════════════════════════════════════════════════════════
  final database = await AppDatabase.getInstance();
  sl.registerSingleton<AppDatabase>(database);

  // ══════════════════════════════════════════════════════════════
  // DAOs (Data Access Objects)
  // ══════════════════════════════════════════════════════════════
  sl.registerLazySingleton(() => database.userDao);
  sl.registerLazySingleton(() => database.practiceSessionDao);
  sl.registerLazySingleton(() => database.lessonDao);
  sl.registerLazySingleton(() => database.pronunciationResultDao);

  // ══════════════════════════════════════════════════════════════
  // REPOSITORIES
  // ══════════════════════════════════════════════════════════════
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(userDao: sl()),
  );
  sl.registerLazySingleton<PracticeSessionRepository>(
    () => PracticeSessionRepositoryImpl(practiceSessionDao: sl()),
  );
  sl.registerLazySingleton<LessonRepository>(
    () => LessonRepositoryImpl(lessonDao: sl()),
  );
  sl.registerLazySingleton<PronunciationResultRepository>(
    () => PronunciationResultRepositoryImpl(pronunciationResultDao: sl()),
  );

  // ══════════════════════════════════════════════════════════════
  // USE CASES — Habit Tracking (Checklist 2 & 6 - Nguyễn Khắc Minh Hiếu)
  // ══════════════════════════════════════════════════════════════
  sl.registerLazySingleton<CalculateStreakUseCase>(
    () => CalculateStreakUseCase(
      sessionRepository: sl(),
      userRepository: sl(),
    ),
  );
  sl.registerLazySingleton<GetHabitStatsUseCase>(
    () => GetHabitStatsUseCase(
      sessionRepository: sl(),
      userRepository: sl(),
    ),
  );

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  sl.registerSingleton<NotificationService>(notificationService);
}
