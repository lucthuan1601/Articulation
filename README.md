# Articulation - Ứng dụng Học Tiếng Anh & Phân tích Phát âm

Dự án ứng dụng di động học tiếng Anh xây dựng bằng Flutter. Ứng dụng kết hợp tính năng theo dõi kỷ luật học tập (Streak & Habit Tracking) và công nghệ AI để phân tích, chấm điểm phát âm của người dùng dựa trên âm vị học (Phonemes).

## 👥 Danh sách thành viên & Phân công nhiệm vụ

| STT | Họ và Tên | MSSV | Vai trò | Nhiệm vụ đảm nhận (Theo Checklist) |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Lục Văn Thuận** | 2351170624 | Nhóm trưởng | **(1)** Thiết kế cơ sở dữ liệu (SQLite/Floor).<br>**(7)** Quản lý chất lượng, kiểm thử đa thiết bị, giọng nói. |
| 2 | **Hoàng Tùng** | 2351170630 | Thành viên | **(3)** Tích hợp API Speech Recognition (thu âm, xử lý giọng nói).<br>**(4)** Xử lý logic AI/thuật toán so sánh âm vị và tính điểm. |
| 3 | **Trần Văn Hồng Quân** | 2351170613 | Thành viên | **(5)** Xây dựng module phản hồi UI/UX (hiển thị màu sắc từ sai, gợi ý IPA, phát lại âm thanh). |
| 4 | **Nguyễn Khắc Minh Hiếu** | 225116000 | Thành viên | **(2)** Xây dựng logic theo dõi tiến độ (tính toán streak, biểu đồ thời gian).<br>**(6)** Tạo hệ thống Push Notification & UI màn hình thống kê. |

---

## 📁 Cấu trúc thư mục (Clean Architecture)

Dự án áp dụng mô hình Clean Architecture để dễ dàng mở rộng và phân chia công việc cho nhiều người.

```text
lib/
├── core/                   # Cấu hình chung: Network (Dio), Theme, Utils, Error handling
├── di/                     # Dependency Injection setup (GetIt, Injectable)
├── features/               # Các tính năng chính của ứng dụng
│   ├── habit_tracking/     # (Logic Streak, Notifications)
│   │   ├── data/           # Models, Floor DAO
│   │   ├── domain/         # Tính toán chuỗi ngày, thống kê biểu đồ
│   │   └── presentation/   # Màn hình Dashboard, Heatmap, Settings
│   └── pronunciation/     
│       ├── data/           # Gọi API Speech-to-Text, bóc tách JSON
│       ├── domain/         # Logic tính điểm, so sánh Phoneme
│       └── presentation/   # UI phòng thu âm, visualizer, bôi màu text, popup IPA
└── shared/                 # Custom Widgets dùng chung toàn app (Buttons, Dialogs)
```

---

## 🗄️ Cấu trúc Cơ sở dữ liệu (Database Schema)

Dự án sử dụng **Floor (SQLite)** để lưu trữ dữ liệu local.

### 1. Bảng `User` (Thông tin & Trạng thái kỷ luật)
*   `id` (TEXT - PK): Mã người dùng.
*   `name` (TEXT): Tên người dùng.
*   `dailyGoalMinutes` (INTEGER): Mục tiêu thời gian học (phút).
*   `currentStreak` (INTEGER): Chuỗi ngày học liên tiếp hiện tại.
*   `longestStreak` (INTEGER): Chuỗi ngày học liên tiếp dài nhất.
*   `lastPracticeDate` (INTEGER): Timestamp ngày học cuối cùng (dùng để tính Streak).
*   `notificationTime` (TEXT): Khung giờ nhắc nhở (VD: "08:00").

### 2. Bảng `Lesson` (Dữ liệu bài học)
*   `id` (TEXT - PK): Mã bài học.
*   `content` (TEXT): Nội dung câu/từ tiếng Anh.
*   `ipaTranscript` (TEXT): Phiên âm chuẩn IPA.
*   `type` (TEXT): Phân loại (word, sentence).

### 3. Bảng `PracticeSession` (Lịch sử luyện tập)
*   `id` (TEXT - PK): Mã phiên học.
*   `date` (INTEGER - Indexed): Timestamp ngày học (tối ưu query cho biểu đồ).
*   `durationSeconds` (INTEGER): Thời lượng luyện tập.
*   `totalScore` (REAL): Điểm trung bình.

### 4. Bảng `PronunciationResult` (Kết quả phân tích chi tiết)
*   `id` (TEXT - PK): Mã kết quả.
*   `sessionId` (TEXT - FK): Liên kết với phiên học.
*   `lessonId` (TEXT - FK): Liên kết với bài học.
*   `audioFilePath` (TEXT): Đường dẫn file `.m4a` hoặc `.wav` trong máy.
*   `accuracyScore` (REAL): Điểm tổng quan của lần đọc.
*   `phonemeDetails` (TEXT): Chuỗi JSON chứa mảng phân tích từng từ (đúng/sai, lỗi âm vị).
