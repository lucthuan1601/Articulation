import 'package:flutter/material.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_theme.dart';
import 'package:articulation/core/database/seed_data.dart';
import 'package:articulation/di/injection.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/lesson_repository.dart';
import 'package:articulation/features/pronunciation/domain/entities/lesson.dart';
import 'package:articulation/features/habit_tracking/domain/entities/user.dart';
import 'package:articulation/features/pronunciation/presentation/screens/practice_screen.dart';

/// Điểm khởi đầu của ứng dụng Articulation
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo các dependencies (Database, DAOs, Repositories)
  await initDependencies();

  runApp(const ArticulationApp());
}

/// Widget gốc của ứng dụng Articulation
class ArticulationApp extends StatelessWidget {
  const ArticulationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Articulation - Học phát âm tiếng Anh AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DatabaseOverviewScreen(),
    );
  }
}

/// Màn hình kiểm tra hoạt động cơ sở dữ liệu trên thiết bị/máy ảo
class DatabaseOverviewScreen extends StatefulWidget {
  const DatabaseOverviewScreen({super.key});

  @override
  State<DatabaseOverviewScreen> createState() => _DatabaseOverviewScreenState();
}

class _DatabaseOverviewScreenState extends State<DatabaseOverviewScreen> {
  bool _isLoading = true;
  User? _currentUser;
  List<Lesson> _lessons = [];
  String _statusMessage = 'Đang kết nối cơ sở dữ liệu SQLite...';

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  /// Tải dữ liệu từ SQLite thông qua Repository
  Future<void> _loadDatabaseData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang đọc dữ liệu từ SQLite (Floor ORM)...';
    });

    try {
      final userRepo = sl<UserRepository>();
      final lessonRepo = sl<LessonRepository>();

      // Lấy hoặc tạo user mặc định
      var user = await userRepo.getUserById('local_user');
      if (user == null) {
        user = User(
          id: 'local_user',
          name: 'Lục Văn Thuận',
          email: 'thuan.luc@articulation.app',
          dailyGoalMinutes: 15,
          currentStreak: 5,
          longestStreak: 12,
          lastPracticeDate: DateTime.now().subtract(const Duration(hours: 3)),
          notificationTime: '08:00',
          isNotificationEnabled: true,
          createdAt: DateTime.now(),
        );
        await userRepo.saveUser(user);
      }

      // Kiểm tra và seed bài học nếu chưa có
      var lessons = await lessonRepo.getAllLessons();
      if (lessons.isEmpty) {
        final seedLessons = SeedData.getAllLessons().map((item) {
          return Lesson(
            id: item['id'] as String,
            content: item['content'] as String,
            ipaTranscript: item['ipaTranscript'] as String,
            vietnameseMeaning: item['vietnameseMeaning'] as String,
            type: LessonType.fromString(item['type'] as String),
            difficulty: DifficultyLevel.fromString(item['difficulty'] as String),
            category: item['category'] as String,
            audioUrl: item['audioUrl'] as String?,
            orderIndex: item['orderIndex'] as int,
          );
        }).toList();

        await lessonRepo.saveLessons(seedLessons);
        lessons = await lessonRepo.getAllLessons();
      }

      setState(() {
        _currentUser = user;
        _lessons = lessons;
        _isLoading = false;
        _statusMessage = 'Kết nối SQLite thành công!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Lỗi kết nối cơ sở dữ liệu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Articulation AI', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadDatabaseData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDatabaseData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner trạng thái CSDL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'SQLite / Floor ORM Đang Hoạt Động',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hệ thống CSDL (Checklist 1) đã được khởi tạo thành công trên thiết bị.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card thông tin Người dùng & Chuỗi Streak
                  if (_currentUser != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primarySurface,
                                child: Text(
                                  _currentUser!.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _currentUser!.email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Streak flame widget
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.streakFlame.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        color: AppColors.streakFlame, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_currentUser!.currentStreak} ngày',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.streakFlame,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Kỷ lục Streak', '${_currentUser!.longestStreak} ngày'),
                              _buildStatItem('Mục tiêu/ngày', '${_currentUser!.dailyGoalMinutes} phút'),
                              _buildStatItem('Nhắc nhở', _currentUser!.notificationTime),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header danh sách bài học
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dữ Liệu Bài Học SQLite (${_lessons.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Preloaded Seed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Danh sách bài học từ SQLite
                  ..._lessons.take(6).map((lesson) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PracticeScreen(
                              lesson: lesson,
                              userId: _currentUser!.id,
                            ),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: lesson.type == LessonType.word
                              ? AppColors.primarySurface
                              : AppColors.secondarySurface,
                          child: Icon(
                            lesson.type == LessonType.word ? Icons.text_fields : Icons.short_text,
                            color: lesson.type == LessonType.word
                                ? AppColors.primary
                                : AppColors.secondaryDark,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          lesson.content,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.ipaTranscript,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              lesson.vietnameseMeaning,
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            lesson.difficulty.displayName,
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Phiên bản 1.0.0 • Checklist 1 hoàn tất',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
