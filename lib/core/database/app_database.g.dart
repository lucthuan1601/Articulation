// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  UserDao? _userDaoInstance;

  LessonDao? _lessonDaoInstance;

  PracticeSessionDao? _practiceSessionDaoInstance;

  PronunciationResultDao? _pronunciationResultDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `users` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `email` TEXT NOT NULL, `avatar_url` TEXT, `daily_goal_minutes` INTEGER NOT NULL, `current_streak` INTEGER NOT NULL, `longest_streak` INTEGER NOT NULL, `last_practice_date` INTEGER, `notification_time` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `is_notification_enabled` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `lessons` (`id` TEXT NOT NULL, `content` TEXT NOT NULL, `ipa_transcript` TEXT NOT NULL, `vietnamese_meaning` TEXT NOT NULL, `type` TEXT NOT NULL, `difficulty` TEXT NOT NULL, `category` TEXT NOT NULL, `audio_url` TEXT, `order_index` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `practice_sessions` (`id` TEXT NOT NULL, `user_id` TEXT NOT NULL, `date` INTEGER NOT NULL, `duration_seconds` INTEGER NOT NULL, `total_score` REAL NOT NULL, `lessons_completed` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE CASCADE, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `pronunciation_results` (`id` TEXT NOT NULL, `session_id` TEXT NOT NULL, `lesson_id` TEXT NOT NULL, `user_id` TEXT NOT NULL, `audio_file_path` TEXT NOT NULL, `accuracy_score` REAL NOT NULL, `fluency_score` REAL NOT NULL, `completeness_score` REAL NOT NULL, `overall_score` REAL NOT NULL, `phoneme_details` TEXT NOT NULL, `feedback` TEXT NOT NULL, `created_at` INTEGER NOT NULL, FOREIGN KEY (`session_id`) REFERENCES `practice_sessions` (`id`) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE CASCADE, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE INDEX `idx_practice_session_date` ON `practice_sessions` (`date`)');
        await database.execute(
            'CREATE INDEX `idx_practice_session_user_id` ON `practice_sessions` (`user_id`)');
        await database.execute(
            'CREATE INDEX `idx_pronunciation_result_session_id` ON `pronunciation_results` (`session_id`)');
        await database.execute(
            'CREATE INDEX `idx_pronunciation_result_lesson_id` ON `pronunciation_results` (`lesson_id`)');
        await database.execute(
            'CREATE INDEX `idx_pronunciation_result_user_id` ON `pronunciation_results` (`user_id`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  UserDao get userDao {
    return _userDaoInstance ??= _$UserDao(database, changeListener);
  }

  @override
  LessonDao get lessonDao {
    return _lessonDaoInstance ??= _$LessonDao(database, changeListener);
  }

  @override
  PracticeSessionDao get practiceSessionDao {
    return _practiceSessionDaoInstance ??=
        _$PracticeSessionDao(database, changeListener);
  }

  @override
  PronunciationResultDao get pronunciationResultDao {
    return _pronunciationResultDaoInstance ??=
        _$PronunciationResultDao(database, changeListener);
  }
}

class _$UserDao extends UserDao {
  _$UserDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _userEntityInsertionAdapter = InsertionAdapter(
            database,
            'users',
            (UserEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'email': item.email,
                  'avatar_url': item.avatarUrl,
                  'daily_goal_minutes': item.dailyGoalMinutes,
                  'current_streak': item.currentStreak,
                  'longest_streak': item.longestStreak,
                  'last_practice_date': item.lastPracticeDate,
                  'notification_time': item.notificationTime,
                  'created_at': item.createdAt,
                  'is_notification_enabled': item.isNotificationEnabled ? 1 : 0
                }),
        _userEntityUpdateAdapter = UpdateAdapter(
            database,
            'users',
            ['id'],
            (UserEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'email': item.email,
                  'avatar_url': item.avatarUrl,
                  'daily_goal_minutes': item.dailyGoalMinutes,
                  'current_streak': item.currentStreak,
                  'longest_streak': item.longestStreak,
                  'last_practice_date': item.lastPracticeDate,
                  'notification_time': item.notificationTime,
                  'created_at': item.createdAt,
                  'is_notification_enabled': item.isNotificationEnabled ? 1 : 0
                }),
        _userEntityDeletionAdapter = DeletionAdapter(
            database,
            'users',
            ['id'],
            (UserEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'email': item.email,
                  'avatar_url': item.avatarUrl,
                  'daily_goal_minutes': item.dailyGoalMinutes,
                  'current_streak': item.currentStreak,
                  'longest_streak': item.longestStreak,
                  'last_practice_date': item.lastPracticeDate,
                  'notification_time': item.notificationTime,
                  'created_at': item.createdAt,
                  'is_notification_enabled': item.isNotificationEnabled ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<UserEntity> _userEntityInsertionAdapter;

  final UpdateAdapter<UserEntity> _userEntityUpdateAdapter;

  final DeletionAdapter<UserEntity> _userEntityDeletionAdapter;

  @override
  Future<List<UserEntity>> findAllUsers() async {
    return _queryAdapter.queryList('SELECT * FROM users',
        mapper: (Map<String, Object?> row) => UserEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            avatarUrl: row['avatar_url'] as String?,
            dailyGoalMinutes: row['daily_goal_minutes'] as int,
            currentStreak: row['current_streak'] as int,
            longestStreak: row['longest_streak'] as int,
            lastPracticeDate: row['last_practice_date'] as int?,
            notificationTime: row['notification_time'] as String,
            createdAt: row['created_at'] as int,
            isNotificationEnabled:
                (row['is_notification_enabled'] as int) != 0));
  }

  @override
  Future<UserEntity?> findUserById(String id) async {
    return _queryAdapter.query('SELECT * FROM users WHERE id = ?1',
        mapper: (Map<String, Object?> row) => UserEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            avatarUrl: row['avatar_url'] as String?,
            dailyGoalMinutes: row['daily_goal_minutes'] as int,
            currentStreak: row['current_streak'] as int,
            longestStreak: row['longest_streak'] as int,
            lastPracticeDate: row['last_practice_date'] as int?,
            notificationTime: row['notification_time'] as String,
            createdAt: row['created_at'] as int,
            isNotificationEnabled:
                (row['is_notification_enabled'] as int) != 0),
        arguments: [id]);
  }

  @override
  Future<void> updateStreak(
    String id,
    int currentStreak,
    int longestStreak,
    int lastPracticeDate,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE users SET current_streak = ?2, longest_streak = ?3, last_practice_date = ?4 WHERE id = ?1',
        arguments: [id, currentStreak, longestStreak, lastPracticeDate]);
  }

  @override
  Future<void> updateDailyGoal(
    String id,
    int minutes,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE users SET daily_goal_minutes = ?2 WHERE id = ?1',
        arguments: [id, minutes]);
  }

  @override
  Future<void> updateNotificationSettings(
    String id,
    String time,
    int enabled,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE users SET notification_time = ?2, is_notification_enabled = ?3 WHERE id = ?1',
        arguments: [id, time, enabled]);
  }

  @override
  Future<void> insertUser(UserEntity user) async {
    await _userEntityInsertionAdapter.insert(user, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    await _userEntityUpdateAdapter.update(user, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteUser(UserEntity user) async {
    await _userEntityDeletionAdapter.delete(user);
  }
}

class _$LessonDao extends LessonDao {
  _$LessonDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _lessonEntityInsertionAdapter = InsertionAdapter(
            database,
            'lessons',
            (LessonEntity item) => <String, Object?>{
                  'id': item.id,
                  'content': item.content,
                  'ipa_transcript': item.ipaTranscript,
                  'vietnamese_meaning': item.vietnameseMeaning,
                  'type': item.type,
                  'difficulty': item.difficulty,
                  'category': item.category,
                  'audio_url': item.audioUrl,
                  'order_index': item.orderIndex
                }),
        _lessonEntityUpdateAdapter = UpdateAdapter(
            database,
            'lessons',
            ['id'],
            (LessonEntity item) => <String, Object?>{
                  'id': item.id,
                  'content': item.content,
                  'ipa_transcript': item.ipaTranscript,
                  'vietnamese_meaning': item.vietnameseMeaning,
                  'type': item.type,
                  'difficulty': item.difficulty,
                  'category': item.category,
                  'audio_url': item.audioUrl,
                  'order_index': item.orderIndex
                }),
        _lessonEntityDeletionAdapter = DeletionAdapter(
            database,
            'lessons',
            ['id'],
            (LessonEntity item) => <String, Object?>{
                  'id': item.id,
                  'content': item.content,
                  'ipa_transcript': item.ipaTranscript,
                  'vietnamese_meaning': item.vietnameseMeaning,
                  'type': item.type,
                  'difficulty': item.difficulty,
                  'category': item.category,
                  'audio_url': item.audioUrl,
                  'order_index': item.orderIndex
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LessonEntity> _lessonEntityInsertionAdapter;

  final UpdateAdapter<LessonEntity> _lessonEntityUpdateAdapter;

  final DeletionAdapter<LessonEntity> _lessonEntityDeletionAdapter;

  @override
  Future<List<LessonEntity>> findAllLessons() async {
    return _queryAdapter.queryList('SELECT * FROM lessons',
        mapper: (Map<String, Object?> row) => LessonEntity(
            id: row['id'] as String,
            content: row['content'] as String,
            ipaTranscript: row['ipa_transcript'] as String,
            vietnameseMeaning: row['vietnamese_meaning'] as String,
            type: row['type'] as String,
            difficulty: row['difficulty'] as String,
            category: row['category'] as String,
            audioUrl: row['audio_url'] as String?,
            orderIndex: row['order_index'] as int));
  }

  @override
  Future<LessonEntity?> findLessonById(String id) async {
    return _queryAdapter.query('SELECT * FROM lessons WHERE id = ?1',
        mapper: (Map<String, Object?> row) => LessonEntity(
            id: row['id'] as String,
            content: row['content'] as String,
            ipaTranscript: row['ipa_transcript'] as String,
            vietnameseMeaning: row['vietnamese_meaning'] as String,
            type: row['type'] as String,
            difficulty: row['difficulty'] as String,
            category: row['category'] as String,
            audioUrl: row['audio_url'] as String?,
            orderIndex: row['order_index'] as int),
        arguments: [id]);
  }

  @override
  Future<List<LessonEntity>> findLessonsByType(String type) async {
    return _queryAdapter.queryList('SELECT * FROM lessons WHERE type = ?1',
        mapper: (Map<String, Object?> row) => LessonEntity(
            id: row['id'] as String,
            content: row['content'] as String,
            ipaTranscript: row['ipa_transcript'] as String,
            vietnameseMeaning: row['vietnamese_meaning'] as String,
            type: row['type'] as String,
            difficulty: row['difficulty'] as String,
            category: row['category'] as String,
            audioUrl: row['audio_url'] as String?,
            orderIndex: row['order_index'] as int),
        arguments: [type]);
  }

  @override
  Future<List<LessonEntity>> findLessonsByDifficulty(String difficulty) async {
    return _queryAdapter.queryList(
        'SELECT * FROM lessons WHERE difficulty = ?1',
        mapper: (Map<String, Object?> row) => LessonEntity(
            id: row['id'] as String,
            content: row['content'] as String,
            ipaTranscript: row['ipa_transcript'] as String,
            vietnameseMeaning: row['vietnamese_meaning'] as String,
            type: row['type'] as String,
            difficulty: row['difficulty'] as String,
            category: row['category'] as String,
            audioUrl: row['audio_url'] as String?,
            orderIndex: row['order_index'] as int),
        arguments: [difficulty]);
  }

  @override
  Future<List<LessonEntity>> findLessonsByCategory(String category) async {
    return _queryAdapter.queryList('SELECT * FROM lessons WHERE category = ?1',
        mapper: (Map<String, Object?> row) => LessonEntity(
            id: row['id'] as String,
            content: row['content'] as String,
            ipaTranscript: row['ipa_transcript'] as String,
            vietnameseMeaning: row['vietnamese_meaning'] as String,
            type: row['type'] as String,
            difficulty: row['difficulty'] as String,
            category: row['category'] as String,
            audioUrl: row['audio_url'] as String?,
            orderIndex: row['order_index'] as int),
        arguments: [category]);
  }

  @override
  Future<List<LessonEntity>> findLessonsByTypeAndDifficulty(
    String type,
    String difficulty,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM lessons WHERE type = ?1 AND difficulty = ?2',
        mapper: (Map<String, Object?> row) => LessonEntity(
            id: row['id'] as String,
            content: row['content'] as String,
            ipaTranscript: row['ipa_transcript'] as String,
            vietnameseMeaning: row['vietnamese_meaning'] as String,
            type: row['type'] as String,
            difficulty: row['difficulty'] as String,
            category: row['category'] as String,
            audioUrl: row['audio_url'] as String?,
            orderIndex: row['order_index'] as int),
        arguments: [type, difficulty]);
  }

  @override
  Future<void> insertLesson(LessonEntity lesson) async {
    await _lessonEntityInsertionAdapter.insert(
        lesson, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertLessons(List<LessonEntity> lessons) async {
    await _lessonEntityInsertionAdapter.insertList(
        lessons, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateLesson(LessonEntity lesson) async {
    await _lessonEntityUpdateAdapter.update(lesson, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteLesson(LessonEntity lesson) async {
    await _lessonEntityDeletionAdapter.delete(lesson);
  }
}

class _$PracticeSessionDao extends PracticeSessionDao {
  _$PracticeSessionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _practiceSessionEntityInsertionAdapter = InsertionAdapter(
            database,
            'practice_sessions',
            (PracticeSessionEntity item) => <String, Object?>{
                  'id': item.id,
                  'user_id': item.userId,
                  'date': item.date,
                  'duration_seconds': item.durationSeconds,
                  'total_score': item.totalScore,
                  'lessons_completed': item.lessonsCompleted,
                  'created_at': item.createdAt
                }),
        _practiceSessionEntityUpdateAdapter = UpdateAdapter(
            database,
            'practice_sessions',
            ['id'],
            (PracticeSessionEntity item) => <String, Object?>{
                  'id': item.id,
                  'user_id': item.userId,
                  'date': item.date,
                  'duration_seconds': item.durationSeconds,
                  'total_score': item.totalScore,
                  'lessons_completed': item.lessonsCompleted,
                  'created_at': item.createdAt
                }),
        _practiceSessionEntityDeletionAdapter = DeletionAdapter(
            database,
            'practice_sessions',
            ['id'],
            (PracticeSessionEntity item) => <String, Object?>{
                  'id': item.id,
                  'user_id': item.userId,
                  'date': item.date,
                  'duration_seconds': item.durationSeconds,
                  'total_score': item.totalScore,
                  'lessons_completed': item.lessonsCompleted,
                  'created_at': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<PracticeSessionEntity>
      _practiceSessionEntityInsertionAdapter;

  final UpdateAdapter<PracticeSessionEntity>
      _practiceSessionEntityUpdateAdapter;

  final DeletionAdapter<PracticeSessionEntity>
      _practiceSessionEntityDeletionAdapter;

  @override
  Future<List<PracticeSessionEntity>> findAllSessions() async {
    return _queryAdapter.queryList('SELECT * FROM practice_sessions',
        mapper: (Map<String, Object?> row) => PracticeSessionEntity(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            date: row['date'] as int,
            durationSeconds: row['duration_seconds'] as int,
            totalScore: row['total_score'] as double,
            lessonsCompleted: row['lessons_completed'] as int,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<PracticeSessionEntity?> findSessionById(String id) async {
    return _queryAdapter.query('SELECT * FROM practice_sessions WHERE id = ?1',
        mapper: (Map<String, Object?> row) => PracticeSessionEntity(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            date: row['date'] as int,
            durationSeconds: row['duration_seconds'] as int,
            totalScore: row['total_score'] as double,
            lessonsCompleted: row['lessons_completed'] as int,
            createdAt: row['created_at'] as int),
        arguments: [id]);
  }

  @override
  Future<List<PracticeSessionEntity>> findSessionsByUserId(
      String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM practice_sessions WHERE user_id = ?1 ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => PracticeSessionEntity(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            date: row['date'] as int,
            durationSeconds: row['duration_seconds'] as int,
            totalScore: row['total_score'] as double,
            lessonsCompleted: row['lessons_completed'] as int,
            createdAt: row['created_at'] as int),
        arguments: [userId]);
  }

  @override
  Future<List<PracticeSessionEntity>> findSessionsByDateRange(
    String userId,
    int startDate,
    int endDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM practice_sessions WHERE user_id = ?1 AND date >= ?2 AND date <= ?3 ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => PracticeSessionEntity(id: row['id'] as String, userId: row['user_id'] as String, date: row['date'] as int, durationSeconds: row['duration_seconds'] as int, totalScore: row['total_score'] as double, lessonsCompleted: row['lessons_completed'] as int, createdAt: row['created_at'] as int),
        arguments: [userId, startDate, endDate]);
  }

  @override
  Future<PracticeSessionEntity?> findTodaySession(
    String userId,
    int todayStart,
    int todayEnd,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM practice_sessions WHERE user_id = ?1 AND date >= ?2 AND date <= ?3 LIMIT 1',
        mapper: (Map<String, Object?> row) => PracticeSessionEntity(id: row['id'] as String, userId: row['user_id'] as String, date: row['date'] as int, durationSeconds: row['duration_seconds'] as int, totalScore: row['total_score'] as double, lessonsCompleted: row['lessons_completed'] as int, createdAt: row['created_at'] as int),
        arguments: [userId, todayStart, todayEnd]);
  }

  @override
  Future<int?> getTotalPracticeTime(String userId) async {
    return _queryAdapter.query(
        'SELECT SUM(duration_seconds) FROM practice_sessions WHERE user_id = ?1',
        mapper: (Map<String, Object?> row) => (row.values.first as num?)?.toInt() ?? 0,
        arguments: [userId]);
  }

  @override
  Future<double?> getAverageScore(String userId) async {
    return _queryAdapter.query(
        'SELECT AVG(total_score) FROM practice_sessions WHERE user_id = ?1',
        mapper: (Map<String, Object?> row) => (row.values.first as num?)?.toDouble() ?? 0.0,
        arguments: [userId]);
  }

  @override
  Future<int?> getSessionCount(String userId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM practice_sessions WHERE user_id = ?1',
        mapper: (Map<String, Object?> row) => (row.values.first as num?)?.toInt() ?? 0,
        arguments: [userId]);
  }

  @override
  Future<void> insertSession(PracticeSessionEntity session) async {
    await _practiceSessionEntityInsertionAdapter.insert(
        session, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateSession(PracticeSessionEntity session) async {
    await _practiceSessionEntityUpdateAdapter.update(
        session, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteSession(PracticeSessionEntity session) async {
    await _practiceSessionEntityDeletionAdapter.delete(session);
  }
}

class _$PronunciationResultDao extends PronunciationResultDao {
  _$PronunciationResultDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _pronunciationResultEntityInsertionAdapter = InsertionAdapter(
            database,
            'pronunciation_results',
            (PronunciationResultEntity item) => <String, Object?>{
                  'id': item.id,
                  'session_id': item.sessionId,
                  'lesson_id': item.lessonId,
                  'user_id': item.userId,
                  'audio_file_path': item.audioFilePath,
                  'accuracy_score': item.accuracyScore,
                  'fluency_score': item.fluencyScore,
                  'completeness_score': item.completenessScore,
                  'overall_score': item.overallScore,
                  'phoneme_details': item.phonemeDetails,
                  'feedback': item.feedback,
                  'created_at': item.createdAt
                }),
        _pronunciationResultEntityUpdateAdapter = UpdateAdapter(
            database,
            'pronunciation_results',
            ['id'],
            (PronunciationResultEntity item) => <String, Object?>{
                  'id': item.id,
                  'session_id': item.sessionId,
                  'lesson_id': item.lessonId,
                  'user_id': item.userId,
                  'audio_file_path': item.audioFilePath,
                  'accuracy_score': item.accuracyScore,
                  'fluency_score': item.fluencyScore,
                  'completeness_score': item.completenessScore,
                  'overall_score': item.overallScore,
                  'phoneme_details': item.phonemeDetails,
                  'feedback': item.feedback,
                  'created_at': item.createdAt
                }),
        _pronunciationResultEntityDeletionAdapter = DeletionAdapter(
            database,
            'pronunciation_results',
            ['id'],
            (PronunciationResultEntity item) => <String, Object?>{
                  'id': item.id,
                  'session_id': item.sessionId,
                  'lesson_id': item.lessonId,
                  'user_id': item.userId,
                  'audio_file_path': item.audioFilePath,
                  'accuracy_score': item.accuracyScore,
                  'fluency_score': item.fluencyScore,
                  'completeness_score': item.completenessScore,
                  'overall_score': item.overallScore,
                  'phoneme_details': item.phonemeDetails,
                  'feedback': item.feedback,
                  'created_at': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<PronunciationResultEntity>
      _pronunciationResultEntityInsertionAdapter;

  final UpdateAdapter<PronunciationResultEntity>
      _pronunciationResultEntityUpdateAdapter;

  final DeletionAdapter<PronunciationResultEntity>
      _pronunciationResultEntityDeletionAdapter;

  @override
  Future<List<PronunciationResultEntity>> findAllResults() async {
    return _queryAdapter.queryList('SELECT * FROM pronunciation_results',
        mapper: (Map<String, Object?> row) => PronunciationResultEntity(
            id: row['id'] as String,
            sessionId: row['session_id'] as String,
            lessonId: row['lesson_id'] as String,
            userId: row['user_id'] as String,
            audioFilePath: row['audio_file_path'] as String,
            accuracyScore: row['accuracy_score'] as double,
            fluencyScore: row['fluency_score'] as double,
            completenessScore: row['completeness_score'] as double,
            overallScore: row['overall_score'] as double,
            phonemeDetails: row['phoneme_details'] as String,
            feedback: row['feedback'] as String,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<PronunciationResultEntity?> findResultById(String id) async {
    return _queryAdapter.query(
        'SELECT * FROM pronunciation_results WHERE id = ?1',
        mapper: (Map<String, Object?> row) => PronunciationResultEntity(
            id: row['id'] as String,
            sessionId: row['session_id'] as String,
            lessonId: row['lesson_id'] as String,
            userId: row['user_id'] as String,
            audioFilePath: row['audio_file_path'] as String,
            accuracyScore: row['accuracy_score'] as double,
            fluencyScore: row['fluency_score'] as double,
            completenessScore: row['completeness_score'] as double,
            overallScore: row['overall_score'] as double,
            phonemeDetails: row['phoneme_details'] as String,
            feedback: row['feedback'] as String,
            createdAt: row['created_at'] as int),
        arguments: [id]);
  }

  @override
  Future<List<PronunciationResultEntity>> findResultsBySessionId(
      String sessionId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM pronunciation_results WHERE session_id = ?1 ORDER BY created_at ASC',
        mapper: (Map<String, Object?> row) => PronunciationResultEntity(id: row['id'] as String, sessionId: row['session_id'] as String, lessonId: row['lesson_id'] as String, userId: row['user_id'] as String, audioFilePath: row['audio_file_path'] as String, accuracyScore: row['accuracy_score'] as double, fluencyScore: row['fluency_score'] as double, completenessScore: row['completeness_score'] as double, overallScore: row['overall_score'] as double, phonemeDetails: row['phoneme_details'] as String, feedback: row['feedback'] as String, createdAt: row['created_at'] as int),
        arguments: [sessionId]);
  }

  @override
  Future<List<PronunciationResultEntity>> findResultsByUserId(
      String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM pronunciation_results WHERE user_id = ?1 ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => PronunciationResultEntity(id: row['id'] as String, sessionId: row['session_id'] as String, lessonId: row['lesson_id'] as String, userId: row['user_id'] as String, audioFilePath: row['audio_file_path'] as String, accuracyScore: row['accuracy_score'] as double, fluencyScore: row['fluency_score'] as double, completenessScore: row['completeness_score'] as double, overallScore: row['overall_score'] as double, phonemeDetails: row['phoneme_details'] as String, feedback: row['feedback'] as String, createdAt: row['created_at'] as int),
        arguments: [userId]);
  }

  @override
  Future<List<PronunciationResultEntity>> findResultsByLessonId(
    String userId,
    String lessonId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM pronunciation_results WHERE user_id = ?1 AND lesson_id = ?2 ORDER BY created_at DESC',
        mapper: (Map<String, Object?> row) => PronunciationResultEntity(id: row['id'] as String, sessionId: row['session_id'] as String, lessonId: row['lesson_id'] as String, userId: row['user_id'] as String, audioFilePath: row['audio_file_path'] as String, accuracyScore: row['accuracy_score'] as double, fluencyScore: row['fluency_score'] as double, completenessScore: row['completeness_score'] as double, overallScore: row['overall_score'] as double, phonemeDetails: row['phoneme_details'] as String, feedback: row['feedback'] as String, createdAt: row['created_at'] as int),
        arguments: [userId, lessonId]);
  }

  @override
  Future<double?> getAverageAccuracy(String userId) async {
    return _queryAdapter.query(
        'SELECT AVG(accuracy_score) FROM pronunciation_results WHERE user_id = ?1',
        mapper: (Map<String, Object?> row) => (row.values.first as num?)?.toDouble() ?? 0.0,
        arguments: [userId]);
  }

  @override
  Future<double?> getBestScoreForLesson(
    String userId,
    String lessonId,
  ) async {
    return _queryAdapter.query(
        'SELECT MAX(overall_score) FROM pronunciation_results WHERE user_id = ?1 AND lesson_id = ?2',
        mapper: (Map<String, Object?> row) => (row.values.first as num?)?.toDouble() ?? 0.0,
        arguments: [userId, lessonId]);
  }

  @override
  Future<List<PronunciationResultEntity>> getRecentResults(
    String userId,
    int limit,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM pronunciation_results WHERE user_id = ?1 ORDER BY created_at DESC LIMIT ?2',
        mapper: (Map<String, Object?> row) => PronunciationResultEntity(id: row['id'] as String, sessionId: row['session_id'] as String, lessonId: row['lesson_id'] as String, userId: row['user_id'] as String, audioFilePath: row['audio_file_path'] as String, accuracyScore: row['accuracy_score'] as double, fluencyScore: row['fluency_score'] as double, completenessScore: row['completeness_score'] as double, overallScore: row['overall_score'] as double, phonemeDetails: row['phoneme_details'] as String, feedback: row['feedback'] as String, createdAt: row['created_at'] as int),
        arguments: [userId, limit]);
  }

  @override
  Future<void> insertResult(PronunciationResultEntity result) async {
    await _pronunciationResultEntityInsertionAdapter.insert(
        result, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateResult(PronunciationResultEntity result) async {
    await _pronunciationResultEntityUpdateAdapter.update(
        result, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteResult(PronunciationResultEntity result) async {
    await _pronunciationResultEntityDeletionAdapter.delete(result);
  }
}
