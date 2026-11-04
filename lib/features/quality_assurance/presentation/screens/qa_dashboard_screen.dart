import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:articulation/core/services/voice_service.dart';
import 'package:articulation/core/theme/app_colors.dart';
import 'package:articulation/core/theme/app_text_styles.dart';
import 'package:articulation/di/injection.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/practice_session_repository.dart';
import 'package:articulation/features/habit_tracking/domain/repositories/user_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/lesson_repository.dart';
import 'package:articulation/features/pronunciation/domain/repositories/pronunciation_result_repository.dart';
import 'package:articulation/features/quality_assurance/domain/models/qa_diagnostics.dart';

/// Màn hình Trung tâm Quản lý chất lượng & Kiểm thử đa thiết bị (Checklist 7 - Lục Văn Thuận)
class QaDashboardScreen extends StatefulWidget {
  const QaDashboardScreen({super.key});

  @override
  State<QaDashboardScreen> createState() => _QaDashboardScreenState();
}

class _QaDashboardScreenState extends State<QaDashboardScreen> {
  // Voice test state
  String _selectedVoiceSample = 'think so';
  double _voiceSpeed = 1.0;
  bool _isPlayingVoice = false;

  // DB diagnostic stats
  bool _isLoadingDbStats = true;
  int _userCount = 0;
  int _lessonCount = 0;
  int _sessionCount = 0;
  int _resultCount = 0;
  String _dbStatusText = 'Đang kiểm tra CSDL...';

  // Vietnamese accent test state
  String _testWord = 'think';
  String _testTargetIpa = 'θɪŋk';
  String _testHeardIpa = 'tɪŋk';
  Map<String, dynamic>? _accentTestResult;


  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
    _runAccentTest();
  }

  Future<void> _loadDatabaseStats() async {
    setState(() {
      _isLoadingDbStats = true;
      _dbStatusText = 'Đang truy vấn bảng SQLite...';
    });

    try {
      final userRepo = sl<UserRepository>();
      final lessonRepo = sl<LessonRepository>();
      final sessionRepo = sl<PracticeSessionRepository>();
      final resultRepo = sl<PronunciationResultRepository>();

      final user = await userRepo.getUserById('local_user');
      final lessons = await lessonRepo.getAllLessons();
      final sessions = await sessionRepo.getSessionsByUserId('local_user');
      final results = await resultRepo.getResultsByUserId('local_user');

      if (mounted) {
        setState(() {
          _userCount = user != null ? 1 : 0;
          _lessonCount = lessons.length;
          _sessionCount = sessions.length;
          _resultCount = results.length;
          _isLoadingDbStats = false;
          _dbStatusText = 'Cơ sở dữ liệu hoạt động hoàn hảo (${kIsWeb ? 'Web FFI' : 'Android SQLite'})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDbStats = false;
          _dbStatusText = 'Lỗi kiểm tra CSDL: $e';
        });
      }
    }
  }

  void _runAccentTest() {
    setState(() {
      _accentTestResult = VoiceService.analyzeVietnameseLearnerMistakes(
        targetWord: _testWord,
        targetIpa: _testTargetIpa,
        heardIpa: _testHeardIpa,
      );
    });
  }

  Future<void> _playVoiceSample() async {
    setState(() => _isPlayingVoice = true);
    final url = VoiceService.getPronunciationUrl(_selectedVoiceSample);
    await VoiceService().playAudio(url, speed: _voiceSpeed);
    if (mounted) {
      setState(() => _isPlayingVoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final deviceType = DeviceScreenType.fromWidth(screenSize.width);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Quản lý chất lượng & QA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Kiểm tra lại hệ thống',
            onPressed: () {
              _loadDatabaseStats();
              _runAccentTest();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 1. Device & Responsive Breakpoint Banner ──
              _buildDeviceBreakpointCard(screenSize, deviceType),
              const SizedBox(height: 16),

              // ── 2. CSDL & Health Check ──
              _buildDatabaseHealthCard(),
              const SizedBox(height: 16),

              // ── 3. Voice & Giọng nói Testing Center ──
              _buildVoiceTestingCard(),
              const SizedBox(height: 16),

              // ── 4. Vietnamese Accent & Phoneme AI Test ──
              _buildVietnameseAccentCard(),
              const SizedBox(height: 16),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceBreakpointCard(Size size, DeviceScreenType type) {
    String platformName = 'Desktop / Windows';
    if (kIsWeb) {
      platformName = 'Web Browser (Chrome/Edge)';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      platformName = 'Android (Thiết bị / Máy ảo)';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Kiểm thử đa thiết bị & Màn hình', style: AppTextStyles.h4),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type.displayName.split(' (').first,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Nền tảng', platformName, Icons.computer),
                _buildInfoItem(
                  'Kích thước',
                  '${size.width.toInt()} x ${size.height.toInt()} px',
                  Icons.aspect_ratio,
                ),
                _buildInfoItem(
                  'Phân loại',
                  type == DeviceScreenType.mobile
                      ? 'Điện thoại'
                      : (type == DeviceScreenType.tablet ? 'Tablet' : 'Desktop/Web'),
                  Icons.smartphone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseHealthCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_rounded, color: AppColors.secondaryDark, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Độ toàn vẹn Cơ sở dữ liệu', style: AppTextStyles.h4),
                ),
                const SizedBox(width: 8),
                if (_isLoadingDbStats)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(_dbStatusText, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatNumber('Người dùng', '$_userCount'),
                _buildStatNumber('Bài học', '$_lessonCount'),
                _buildStatNumber('Phiên học', '$_sessionCount'),
                _buildStatNumber('Kết quả phát âm', '$_resultCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceTestingCard() {
    const samples = [
      'think so',
      'I would like a cup of coffee',
      'articulation',
      'practice makes perfect',
      'together we achieve more',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Kiểm thử giọng nói & TTS', style: AppTextStyles.h4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kiểm tra khả năng phát âm chuẩn bản ngữ cho câu và từ tiếng Anh:',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: samples.map((sample) {
                final isSelected = _selectedVoiceSample == sample;
                return ChoiceChip(
                  label: Text(sample),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedVoiceSample = sample);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tốc độ đọc:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<double>(
                      value: _voiceSpeed,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 0.75, child: Text('0.75x (Chậm)')),
                        DropdownMenuItem(value: 1.0, child: Text('1.0x (Chuẩn)')),
                        DropdownMenuItem(value: 1.25, child: Text('1.25x (Nhanh)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _voiceSpeed = val);
                      },
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _isPlayingVoice ? null : _playVoiceSample,
                  icon: Icon(_isPlayingVoice ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_isPlayingVoice ? 'Đang phát...' : 'Phát âm mẫu'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVietnameseAccentCard() {
    final result = _accentTestResult;
    final accuracy = (result?['accuracy'] as num?)?.toDouble() ?? 100.0;
    final issues = (result?['issues'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.streakFlame, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Chẩn đoán âm vị giọng người Việt', style: AppTextStyles.h4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mô phỏng và phát hiện lỗi âm vị thường gặp của người Việt khi học tiếng Anh:',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Từ mục tiêu:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('$_testWord /$_testTargetIpa/', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Người học đọc:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('/$_testHeardIpa/', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.error)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accuracy >= 60 ? AppColors.warningLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${accuracy.toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accuracy >= 60 ? AppColors.warning : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(child: Text(issue, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _testWord = 'think';
                      _testTargetIpa = 'θɪŋk';
                      _testHeardIpa = 'tɪŋk';
                      _runAccentTest();
                    });
                  },
                  child: const Text('Lỗi θ -> t'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _testWord = 'like';
                      _testTargetIpa = 'laɪk';
                      _testHeardIpa = 'laɪ';
                      _runAccentTest();
                    });
                  },
                  child: const Text('Mất âm /k/ cuối'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _testWord = 'coffee';
                      _testTargetIpa = 'ˈkɔːfi';
                      _testHeardIpa = 'ˈkɑfi';
                      _runAccentTest();
                    });
                  },
                  child: const Text('Lỗi nguyên âm /ɔː/'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatNumber(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondaryDark)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
