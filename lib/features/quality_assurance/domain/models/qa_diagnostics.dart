/// Mô hình dữ liệu quản lý chất lượng và kiểm thử (Checklist 7)
enum DeviceScreenType {
  mobile('Mobile Phone (< 600px)', 360, 640),
  tablet('Tablet / Foldable (600px - 900px)', 768, 1024),
  desktopWeb('Desktop Web (> 900px)', 1280, 800);

  final String displayName;
  final double defaultWidth;
  final double defaultHeight;

  const DeviceScreenType(this.displayName, this.defaultWidth, this.defaultHeight);

  static DeviceScreenType fromWidth(double width) {
    if (width < 600) return DeviceScreenType.mobile;
    if (width <= 900) return DeviceScreenType.tablet;
    return DeviceScreenType.desktopWeb;
  }
}

/// Trạng thái của từng checklist trong 7 checklist
class ChecklistStatus {
  final int number;
  final String title;
  final String assignee;
  final String role;
  final String status;
  final bool isCompleted;
  final List<String> details;

  const ChecklistStatus({
    required this.number,
    required this.title,
    required this.assignee,
    required this.role,
    required this.status,
    required this.isCompleted,
    required this.details,
  });

  static List<ChecklistStatus> getAllChecklists() {
    return const [
      ChecklistStatus(
        number: 1,
        title: 'Thiết kế cơ sở dữ liệu (SQLite/Floor)',
        assignee: 'Lục Văn Thuận (2351170624)',
        role: 'Nhóm trưởng',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          '4 bảng: User, Lesson, PracticeSession, PronunciationResult',
          'Floor ORM + DAOs với các query thống kê & CRUD',
          'Tương thích đa nền tảng (Android SQLite + Web sqflite_ffi_web)',
          'Preloaded Seed Data đầy đủ bài học từ và câu',
        ],
      ),
      ChecklistStatus(
        number: 2,
        title: 'Logic theo dõi tiến độ (Streak & Biểu đồ)',
        assignee: 'Nguyễn Khắc Minh Hiếu (225116000)',
        role: 'Thành viên',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          'CalculateStreakUseCase: tính toán chuỗi ngày học liên tục',
          'Xử lý bảo lưu kỷ lục longestStreak và reset khi gián đoạn',
          'GetHabitStatsUseCase: thống kê thời gian 7 ngày & 90 ngày',
          'Tự động đồng bộ streak sau mỗi lần luyện phát âm',
        ],
      ),
      ChecklistStatus(
        number: 3,
        title: 'Tích hợp API Speech Recognition (Thu âm & Xử lý)',
        assignee: 'Hoàng Tùng (2351170630)',
        role: 'Thành viên',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          'WavSpeechRecorder: thu âm 16kHz mono PCM WAV chuẩn AI',
          'SpeechApiClient qua Dio kết nối AI Server HTTP',
          'Tương thích đa thiết bị: Android micro và Web audio recording',
          'Cấp quyền micro và tự động ngắt an toàn ở 29s',
        ],
      ),
      ChecklistStatus(
        number: 4,
        title: 'Xử lý logic AI / So sánh âm vị & Tính điểm',
        assignee: 'Hoàng Tùng (2351170630)',
        role: 'Thành viên',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          'SpeechAnalysisModel bóc tách kết quả chi tiết từng âm vị',
          'Chấm 4 chỉ số: Overall, Accuracy, Fluency, Completeness',
          'Phát hiện lỗi đặc thù: /θ/->/t/, nuốt âm cuối, lạc đề (off-target)',
          'ai_server chạy Node.js với 57/57 unit test đạt chuẩn',
        ],
      ),
      ChecklistStatus(
        number: 5,
        title: 'Module phản hồi UI/UX (Màu sắc, IPA, Audio)',
        assignee: 'Trần Văn Hồng Quân (2351170613)',
        role: 'Thành viên',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          'ColoredTranscript: bôi màu từ đúng (xanh), sai (đỏ), bỏ sót (xám)',
          'IpaHintSheet: popup so sánh IPA chuẩn và phát hiện ký tự sai bằng LCS',
          'AudioPlaybackButton: phát lại bản ghi của bạn và audio mẫu',
          'FeedbackDemoScreen phục vụ thử nghiệm giao diện độc lập',
        ],
      ),
      ChecklistStatus(
        number: 6,
        title: 'Push Notification & UI màn hình thống kê',
        assignee: 'Nguyễn Khắc Minh Hiếu (225116000)',
        role: 'Thành viên',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          'NotificationService: thông báo nhắc nhở hàng ngày & mốc streak',
          'HabitDashboardScreen: Streak card, Heatmap 90 ngày, biểu đồ tuần',
          'SettingsScreen: cài đặt giờ thông báo và mục tiêu phút/ngày',
          'An toàn trên Web (không crash khi chạy trên trình duyệt)',
        ],
      ),
      ChecklistStatus(
        number: 7,
        title: 'Quản lý chất lượng, kiểm thử đa thiết bị, giọng nói',
        assignee: 'Lục Văn Thuận (2351170624)',
        role: 'Nhóm trưởng',
        status: 'Hoàn thành',
        isCompleted: true,
        details: [
          'Kiểm thử đa thiết bị (Mobile Phone, Tablet, Desktop Web)',
          'Phát âm chuẩn bản ngữ tự động cho toàn bộ bài học (Voice TTS)',
          'Bộ chẩn đoán chất lượng & độ toàn vẹn CSDL trực quan',
          'Bộ test tự động toàn diện đạt 100% (unit, widget, integration)',
        ],
      ),
    ];
  }
}
