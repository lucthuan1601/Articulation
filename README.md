# Articulation - Ứng dụng Học Tiếng Anh & Phân tích Phát âm

Dự án ứng dụng di động học tiếng Anh xây dựng bằng Flutter. Ứng dụng kết hợp tính năng theo dõi kỷ luật học tập (Streak & Habit Tracking) và công nghệ AI để phân tích, chấm điểm phát âm của người dùng dựa trên âm vị học (Phonemes), hỗ trợ đa nền tảng (**Android** và **Web**).

---

## 👥 Danh sách thành viên & Phân công nhiệm vụ

| STT | Họ và Tên | MSSV | Vai trò | Nhiệm vụ đảm nhận (Theo Checklist) | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Lục Văn Thuận** | 2351170624 | Nhóm trưởng | **(1)** Thiết kế cơ sở dữ liệu (SQLite/Floor).<br>**(7)** Quản lý chất lượng, kiểm thử đa thiết bị, giọng nói. | ✅ Đạt 100% |
| 2 | **Hoàng Tùng** | 2351170630 | Thành viên | **(3)** Tích hợp API Speech Recognition (thu âm, xử lý giọng nói).<br>**(4)** Xử lý logic AI/thuật toán so sánh âm vị và tính điểm. | ✅ Đạt 100% |
| 3 | **Trần Văn Hồng Quân** | 2351170613 | Thành viên | **(5)** Xây dựng module phản hồi UI/UX (hiển thị màu sắc từ sai, gợi ý IPA, phát lại âm thanh). | ✅ Đạt 100% |
| 4 | **Nguyễn Khắc Minh Hiếu** | 225116000 | Thành viên | **(2)** Xây dựng logic theo dõi tiến độ (tính toán streak, biểu đồ thời gian).<br>**(6)** Tạo hệ thống Push Notification & UI màn hình thống kê. | ✅ Đạt 100% |

---

## 📋 Báo cáo Chi tiết 7 Checklist Nhiệm vụ

### ✅ Checklist (1): Thiết kế cơ sở dữ liệu (SQLite/Floor) - *Lục Văn Thuận*
*   **Database Engine:** Floor ORM trên SQLite (`sqflite`), đồng thời kích hoạt fallback Web SQLite FFI qua `sqflite_common_ffi_web` giúp tương thích hoàn toàn trên nền tảng Web.
*   **Thực thể & DAO:** Đầy đủ 4 Entity (`User`, `Lesson`, `PracticeSession`, `PronunciationResult`) với quan hệ Khóa chính / Khóa ngoại và DAO xử lý CRUD bất đồng bộ.
*   **File liên quan:** `lib/core/database/app_database.dart`, `lib/core/database/database_helper.dart`, `lib/features/habit_tracking/data/models/`, `lib/features/pronunciation/data/models/`.

### ✅ Checklist (2): Logic theo dõi tiến độ (Streak & Biểu đồ thời gian) - *Nguyễn Khắc Minh Hiếu*
*   **Logic Streak:** Xây dựng `CalculateStreakUseCase` tính toán chính xác chuỗi ngày học liên tục (`currentStreak`), chuỗi ngày kỷ lục (`longestStreak`), và tự động reset nếu ngắt quãng quá 1 ngày.
*   **Biểu đồ & Dashboard:** Màn hình `HabitDashboardScreen` hiển thị tiến độ học hôm nay, thanh tiến độ mục tiêu, biểu đồ cột thời gian luyện tập 7 ngày gần nhất, và lịch sử phiên học.
*   **Tích hợp liên kết:** Tự động gọi `CalculateStreakUseCase` ngay khi người dùng nộp bài phát âm để cập nhật chuỗi streak tức thì.
*   **File liên quan:** `lib/features/habit_tracking/domain/usecases/calculate_streak.dart`, `lib/features/habit_tracking/presentation/screens/habit_dashboard_screen.dart`.

### ✅ Checklist (3): Tích hợp API Speech Recognition (Thu âm & Xử lý) - *Hoàng Tùng*
*   **Module Thu âm Đa nền tảng:** `WavSpeechRecorder` sử dụng package `record` thu âm PCM 16-bit 16000Hz mono. Hỗ trợ tự động trên Android (lưu file tạm thời) và Web (đọc blob byte array).
*   **Client REST API:** `SpeechApiClient` xây dựng trên `dio`, tự động nhận diện môi trường mạng (Web kết nối `http://127.0.0.1:8787`, Android Emulator kết nối `http://10.0.2.2:8787` qua `AppConstants.aiServerUrl`).
*   **File liên quan:** `lib/features/pronunciation/data/datasources/wav_speech_recorder.dart`, `lib/features/pronunciation/data/datasources/speech_api_client.dart`.

### ✅ Checklist (4): Xử lý logic AI & Thuật toán so sánh âm vị - *Hoàng Tùng*
*   **Backend AI Server:** Server Node.js/Express (`ai_server/`) xử lý thuật toán phân tích phát âm:
    *   Tự động phân tách từ, tra cứu từ điển âm vị CMU Dict.
    *   Thuật toán Levenshtein so sánh khoảng cách âm vị (Phoneme Distance).
    *   Mã hóa ngữ âm Soundex và thuật toán dung sai trọng âm (accent tolerance scoring).
    *   Vượt qua toàn bộ **57/57 unit tests** (`npm test`).
*   **Domain & Entity:** Mô hình `PronunciationResult`, `WordDetail`, `PhonemeDetail` chi tiết điểm từng từ và từng âm vị.
*   **File liên quan:** `ai_server/src/`, `lib/features/pronunciation/domain/entities/pronunciation_result.dart`, `lib/features/pronunciation/data/mappers/pronunciation_result_mapper.dart`.

### ✅ Checklist (5): Xây dựng module phản hồi UI/UX - *Trần Văn Hồng Quân*
*   **Bôi màu trực quan:** Hiển thị câu luyện đọc với từng từ bôi màu trực quan theo độ chính xác:
    *   🟢 **Xanh lá (> 80%):** Phát âm chuẩn xác.
    *   🟡 **Vàng (60% - 80%):** Phát âm tạm ổn, cần cải thiện khẩu hình.
    *   🔴 **Đỏ (< 60%):** Phát âm sai hoặc thiếu âm cuối.
*   **Gợi ý IPA & Khẩu hình:** Chạm vào từ sai để mở bottom sheet `IpaHintSheet` hiển thị phiên âm chuẩn, phiên âm thực tế của học viên, và hướng dẫn đặt lưỡi/môi.
*   **Phát lại âm thanh:** Widget `AudioPlaybackButton` hỗ trợ phát lại file thu âm của người dùng (hỗ trợ cả đường dẫn file máy ảo và blob URL trên Web) và mẫu phát âm chuẩn.
*   **File liên quan:** `lib/features/pronunciation/presentation/widgets/audio_playback_button.dart`, `lib/features/pronunciation/presentation/widgets/ipa_hint_sheet.dart`, `lib/features/pronunciation/presentation/screens/pronunciation_feedback_screen.dart`.

### ✅ Checklist (6): Tạo hệ thống Push Notification & UI Thống kê - *Nguyễn Khắc Minh Hiếu*
*   **Hệ thống Push Notification:** Tích hợp `flutter_local_notifications` và `flutter_timezone` (được nâng cấp tương thích Kotlin 2.0 / Java 17).
*   **Khả năng tương thích Web:** Bổ sung cơ chế bảo vệ `kIsWeb` giúp ứng dụng không bị crash khi chạy trên môi trường trình duyệt không hỗ trợ notification native.
*   **Màn hình Cài đặt:** Cho phép người dùng bật/tắt nhắc nhở, tùy chỉnh giờ học hàng ngày, lưu trạng thái vào CSDL.
*   **File liên quan:** `lib/core/notifications/notification_service.dart`, `lib/features/habit_tracking/presentation/screens/settings_screen.dart`.

### ✅ Checklist (7): Quản lý chất lượng, Kiểm thử đa thiết bị & Giọng nói - *Lục Văn Thuận*
*   **Dịch vụ Giọng nói Chuẩn hóa (`VoiceService`):**
    *   Tự động sinh audio mẫu chuẩn bản xứ qua kho lưu trữ âm thanh chuẩn quốc tế và Web Speech TTS.
    *   Tích hợp thuật toán chẩn đoán lỗi âm vị đặc trưng của người học Việt Nam (`analyzeVietnameseLearnerMistakes`): phân tích các lỗi nuốt âm cuối (*final consonants* như `/s/`, `/t/`, `/k/`), nhầm lẫn âm vô thanh/hữu thanh (`/θ/` vs `/t/`, `/ð/` vs `/d/`, `/ʃ/` vs `/s/`).
*   **Kiểm thử Đa thiết bị (Multi-Device Testing):**
    *   Xây dựng hệ thống Breakpoints phân loại thiết bị: Mobile Phone (< 600px), Tablet (600 - 900px), Desktop Web (> 900px).
    *   Áp dụng layout co giãn thông minh (`LayoutBuilder`, `ConstrainedBox` với `maxWidth: 650` và `maxWidth: 800`) giúp màn hình không bị vỡ bố cục trên màn hình lớn.
    *   Bộ Widget Test `test/multi_device_test.dart` kiểm thử tự động giao diện trên 3 độ phân giải tiêu chuẩn: Mobile (360x640), Tablet (768x1024), Desktop Web (1280x800).
*   **Màn hình QA Dashboard (`QaDashboardScreen`):**
    *   Màn hình Quản lý chất lượng trực quan: Kiểm tra kết nối CSDL theo thời gian thực, phát mẫu giọng đọc kiểm thử, mô phỏng chẩn đoán lỗi phát âm tiếng Việt, và bảng kiểm tra trạng thái 7 checklist.
*   **File liên quan:** `lib/core/services/voice_service.dart`, `lib/features/quality_assurance/`, `test/multi_device_test.dart`, `test/voice_quality_test.dart`, `test/qa_diagnostics_test.dart`.

---

## 📁 Cấu trúc thư mục (Clean Architecture)

```text
lib/
├── core/
│   ├── database/           # SQLite / Floor DB helper & AppDatabase (có hỗ trợ Web FFI)
│   ├── errors/             # Custom Failures & Exception handling
│   ├── notifications/      # NotificationService (Web-guarded)
│   ├── services/           # VoiceService (Native Audio, Accent Analyzer)
│   ├── theme/              # AppTheme & Colors
│   └── utils/              # AppConstants, URL helpers, Audio recording constants
├── di/                     # Dependency Injection (GetIt) đăng ký tất cả UseCase & Repository
├── features/
│   ├── habit_tracking/     # Module Kỷ luật & Thói quen (Checklist 2 & 6)
│   │   ├── data/           # Models, Floor DAOs, Repositories
│   │   ├── domain/         # CalculateStreakUseCase, User & Practice Entities
│   │   └── presentation/   # HabitDashboardScreen, SettingsScreen, Widgets
│   ├── pronunciation/      # Module Luyện phát âm & AI (Checklist 3, 4, 5)
│   │   ├── data/           # SpeechApiClient, WavSpeechRecorder, ResultMapper
│   │   ├── domain/         # AnalyzePronunciationUseCase, PronunciationResult Entity
│   │   └── presentation/   # PracticeScreen, PronunciationFeedbackScreen, IpaHintSheet
│   └── quality_assurance/  # Module Quản lý chất lượng & Kiểm thử (Checklist 7)
│       ├── domain/         # QA Diagnostics Models, Breakpoint Enum
│       └── presentation/   # QaDashboardScreen, Live DB Check, Voice Tester
└── main.dart               # Điểm khởi chạy ứng dụng & Navigation đa tab (Mobile/Tablet/Web)
```

---

## 🚀 Hướng dẫn Cài đặt & Khởi chạy Ứng dụng

### 1. Chuẩn bị Môi trường
*   Flutter SDK: `>= 3.10.0`
*   Node.js: `>= 18.0.0` (dùng cho AI Server)
*   Android Studio & SDK (dùng cho Máy ảo Android) hoặc Google Chrome (dùng cho Web)

### 2. Khởi động AI Backend Server
```bash
cd ai_server
npm install
npm test    # Kiểm tra 57 bài test âm vị & chấm điểm
npm start   # Máy chủ AI chạy tại http://127.0.0.1:8787
```

### 3. Chạy Ứng dụng trên Nền tảng Web
```bash
# Cài đặt dependencies
flutter pub get

# Chạy trực tiếp trên trình duyệt Chrome
flutter run -d chrome

# Hoặc build bản web release
flutter build web
```

### 4. Chạy Ứng dụng trên Máy ảo Android (Android Emulator)
```bash
# 1. Khởi động máy ảo (ví dụ: Medium_Phone)
flutter emulators --launch Medium_Phone

# 2. Chạy ứng dụng lên máy ảo
flutter run -d emulator-5554

# Hoặc build file APK cài đặt thủ công:
flutter build apk --debug
# File APK được tạo tại: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🧪 Kết quả Kiểm thử & Quản lý Chất lượng

| Hạng mục kiểm thử | Công cụ | Kết quả | Ghi chú |
| :--- | :--- | :--- | :--- |
| **Phân tích mã nguồn** | `flutter analyze` | ✅ **0 issues** | Không có lỗi, cảnh báo hay linter warning |
| **Flutter Unit & Widget Tests** | `flutter test` | ✅ **41/41 passed** | Bao gồm test UI, Streak, Multi-device, Voice |
| **AI Server Unit Tests** | `npm test` | ✅ **57/57 passed** | Kiểm thử so sánh âm vị, Levenshtein, Soundex |
| **Kiểm thử trên Máy ảo Android** | `Android Emulator API 34` | ✅ **Thành công** | Đã cài đặt APK và chạy tiến trình ổn định |
| **Kiểm thử trên Nền tảng Web** | `Chrome Web Engine (CanvasKit)` | ✅ **Thành công** | Build web hoàn tất, có bảo vệ chống crash Web |
