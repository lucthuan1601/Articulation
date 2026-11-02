import 'package:get_it/get_it.dart';
import 'package:articulation/core/database/app_database.dart';
import 'package:articulation/features/habit_tracking/data/repositories/user_repository_impl.dart';
import 'package:articulation/features/habit_tracking/data/repositories/practice_session_repository_impl.dart';
import 'package:articulation/features/pronunciation/data/repositories/lesson_repository_impl.dart';
import 'package:articulation/features/pronunciation/data/repositories/pronunciation_result_repository_impl.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/lesson_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/pronunciation_result_repository.dart';
import 'package:articulation/core/utils/constants.dart';
import 'package:articulation/features/pronunciation/data/datasources/speech_api_client.dart';
import 'package:articulation/features/pronunciation/data/datasources/wav_speech_recorder.dart';
import 'package:articulation/features/pronunciation/data/repositories/speech_analysis_repository_impl.dart';
import 'package:articulation/features/pronunciation/domain/repositories/speech_analysis_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/speech_recorder.dart';
import 'package:articulation/features/pronunciation/domain/usecases/analyze_pronunciation.dart';

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
  // SPEECH & AI
  // ══════════════════════════════════════════════════════════════
  sl.registerLazySingleton(
    () => SpeechApiClient(baseUrl: AppConstants.aiServerUrl),
  );
  sl.registerLazySingleton<SpeechAnalysisRepository>(
    () => SpeechAnalysisRepositoryImpl(client: sl()),
  );
  sl.registerFactory<SpeechRecorder>(WavSpeechRecorder.new);
  sl.registerLazySingleton(
    () => AnalyzePronunciation(
      analysisRepository: sl(),
      resultRepository: sl(),
      sessionRepository: sl(),
    ),
  );
}
