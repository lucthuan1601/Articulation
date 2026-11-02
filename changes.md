# Nhật ký thay đổi: phần việc của Hoàng Tùng

Cập nhật: 02/11/2026. Phạm vi: mục **(3)** tích hợp Speech Recognition và mục **(4)** logic AI so sánh âm vị, tính điểm.

**Tóm tắt:** phần (3), (4) đã xong về code. Luồng ghi âm, gửi AI, chấm điểm, lưu database và hiển thị đã được nối đầy đủ. **Chưa chạy thử trên thiết bị Android thật hoặc máy ảo, và chưa thử với giọng người Việt.** Chưa có commit hay push nào.

## Thuận và Quân cần xem

Nhánh này không ảnh hưởng `main` cho tới khi được merge. Các mục dưới đây là những gì sẽ tác động tới phần của hai bạn sau khi merge.

### Gửi Thuận

Không đổi cấu trúc bảng: `pronunciation_result_entity.dart` và `app_database.g.dart` giữ nguyên, nên không cần migration hay chạy lại `build_runner`.

| File của bạn | Ban đầu | Sau khi sửa | Lý do |
|---|---|---|---|
| `pronunciation_result_mapper.dart` | Cột `phoneme_details` lưu mảng âm vị: `phoneme`, `accuracyScore`, `assessment` | Lưu mảng theo từ: `word`, `status`, `userIpa`, `correctIpa`, `score`, `suggestion`, và `phonemes` lồng bên trong | Khớp với README và chú thích trong entity. Màn hình của Quân cũng đọc theo dạng này |
| `pronunciation_result.dart` | `PronunciationResult` chỉ có `phonemeDetails` | Thêm lớp `WordDetail` và trường `words`. `phonemeDetails` vẫn có giá trị | Tầng domain cần kết quả theo từ |
| `data/models/phoneme_detail.dart` | 6 trường | Thêm trường tùy chọn `phonemes` | Giữ chi tiết âm vị trong JSON |
| `di/injection.dart` | Database và repository | Thêm client, recorder, repository phân tích, use case | Đăng ký phần mới |
| `main.dart` | Chạm vào bài học không có tác dụng | Chạm để mở `PracticeScreen` | Lối vào tính năng. Danh sách vẫn chỉ hiện 6 bài đầu do `.take(6)` có sẵn |

Cần bạn lưu ý thêm:

| Hạng mục | Nội dung |
|---|---|
| Dữ liệu cũ | Bản ghi chỉ có mảng âm vị vẫn đọc được, `words` sẽ rỗng. Khi đó màn hình phản hồi không có transcript |
| Phiên luyện tập | Mỗi ngày dùng chung một `PracticeSession`, cộng dồn thời lượng, số bài và điểm trung bình. Nếu nhóm muốn mỗi lần mở app là một phiên thì cần đổi `AnalyzePronunciation` |
| Lần đọc sai câu | `offTarget = true` thì không lưu kết quả và không tính vào phiên |
| Build Android | `build.gradle.kts` bật desugaring, manifest bật `usesCleartextTraffic`. Cờ này cũng có hiệu lực ở bản release |
| Thư viện | `record` nâng từ 5.2.1 lên 7.1.2, thêm `dio` và `path`. Sau khi merge cần chạy `flutter pub get` |
| Kiểm thử (checklist 7) | Chưa ai chạy trên thiết bị thật. Cần kiểm tra: xin quyền micro, ghi âm thật, chấm điểm với nhiều giọng người Việt, kết nối điện thoại tới máy chủ AI |
| Mã bài tập | AI trả về các mã như `drill-th-voiceless`, nhưng `seed_data.dart` chưa có bài tương ứng. Danh sách đầy đủ ở `ai_server/docs/ai-module.md` |

### Gửi Quân

Không có file nào trong nhánh của bạn bị sửa.

| Hạng mục | Nội dung |
|---|---|
| Cách nối | `PracticeScreen` mở `PronunciationFeedbackScreen` với `lesson`, `result`, `words`, `onRetry`. `onRetry` quay về màn hình ghi âm |
| Dữ liệu `words` | Tạo trực tiếp từ `result.words`. Với dữ liệu đọc từ database, `WordFeedback.listFromJson(entity.phonemeDetails)` vẫn dùng được và đã được test |
| Trạng thái từ | AI gửi `correct`, `wrong`, `missed`, khớp với `WordStatus.fromString` |
| Trường `userIpa` | Rỗng khi từ bị bỏ sót, nên popup IPA sẽ hiện "Không nghe thấy bạn phát âm từ này" |
| Trường `suggestion` | `null` với từ đọc tốt |
| Điểm thành phần | Cả 4 điểm trên `ScoreSummaryCard` đều có dữ liệu thật |
| Audio người dùng | `result.audioFilePath` là file `.wav` trong thư mục tài liệu của app |
| Audio mẫu | Nút "Nghe phát âm chuẩn" phụ thuộc `lesson.audioUrl`, phần này chưa thay đổi |

Cần bạn quyết định hoặc làm tiếp:

| # | Việc | Chi tiết |
|---|---|---|
| 1 | Giao diện phòng thu | `practice_screen.dart` chỉ là bản tối thiểu để nối luồng. README giao phần này cho bạn, nên bạn có thể thay giao diện. Logic nằm ở `PracticeController` và không cần đổi |
| 2 | Trạng thái "có thể chưa chuẩn" | AI có lỗi không chắc chắn với /θ/, /ð/, /v/. `WordStatus` chỉ có 3 trạng thái nên từ đó vẫn hiện đỏ, chỉ gợi ý ghi "có thể chưa chuẩn". Nên cân nhắc thêm trạng thái thứ tư |
| 3 | Gợi ý bài tập | Khi Thuận có bài `drill-*`, cần thêm nút mở bài luyện. Hiện app chưa giữ lại mã `drill` trong `SpeechAnalysis` |
| 4 | Import thừa | `ipa_hint_sheet.dart:1` đang có một info của `flutter analyze` |
| 5 | Merge | Nhánh này tách từ `feature/quantran`, nên cần merge nhánh của bạn trước hoặc merge cùng lúc |

## 1. Nhánh làm việc

| Hạng mục | Ban đầu | Hiện tại |
|---|---|---|
| Repo cục bộ | Chưa có | `F:\TH3\Articulation` |
| Nhánh | `main` (`5de8bb7`) | `feature/hoangtung`, tách từ `feature/quantran` (`6db482f`), chưa có upstream |

Nhánh chứa sẵn commit của Quân vì màn hình kết quả chỉ có ở đó. Cần merge `feature/quantran` trước, hoặc merge cả hai cùng lúc.

## 2. Kết quả kiểm tra

| Kiểm tra | Trước khi sửa | Sau khi sửa |
|---|---|---|
| Test AI server (`npm test`) | 39/39 | **57/57** |
| Test Flutter (`flutter test`) | 6/6 | **25/25** |
| `flutter analyze` | 1 info | 1 info, vẫn là import thừa có sẵn ở `ipa_hint_sheet.dart:1` |
| `flutter build apk --debug` | Không build được | **Thành công** (cần cờ ở mục 7) |
| API với mô hình thật | Chưa có API | 776 ms cho 2,35 giây âm thanh |
| Dart gọi máy chủ AI thật | Chưa có | Đạt, chi tiết bên dưới |
| Ghi âm bằng micro trên Android | Chưa có | **Chưa kiểm tra**, máy này không có thiết bị |

Kết quả app Dart gọi máy chủ thật, dùng file giọng tổng hợp đọc "I would like a cup of coffee":

| Câu mục tiêu | Tổng | Khác | Kết quả |
|---|---:|---|---|
| Đúng câu đã đọc | 100 | Lưu loát 100 | Đúng |
| Câu đó thêm 5 từ không đọc | 55 | Đầy đủ 58 | 5 từ thiếu được báo `missed` |
| Câu hoàn toàn khác | 24 | `offTarget = true` | Không lưu kết quả |

## 3. Thay đổi file có sẵn

| File | Ban đầu | Thay đổi |
|---|---|---|
| `pubspec.yaml`, `pubspec.lock` | `record ^5.2.0`, chưa có `dio`, `path` | `record ^7.1.2`, thêm `dio ^5.11.1` và `path` |
| `android/app/build.gradle.kts` | Không bật desugaring, app không build được | Bật core library desugaring, thêm `desugar_jdk_libs` |
| `AndroidManifest.xml` | Chặn HTTP không mã hóa | Thêm `usesCleartextTraffic="true"` |
| `core/utils/constants.dart` | Không có cấu hình AI | Thêm `aiServerUrl`, `maxRecordingSeconds`, `recordingSampleRate` |
| `pronunciation_result.dart` | Chỉ có danh sách âm vị | Thêm lớp `WordDetail` và trường `words` |
| `data/models/phoneme_detail.dart` | Chỉ có thông tin theo từ | Thêm trường tùy chọn `phonemes` |
| `pronunciation_result_mapper.dart` | Ghi JSON theo âm vị | Ghi JSON theo từ, lồng âm vị bên trong; vẫn đọc được bản ghi cũ |
| `di/injection.dart` | Chưa có dịch vụ ghi âm và AI | Đăng ký client, recorder, repository, use case |
| `main.dart` | Chạm vào bài học không có tác dụng | Chạm để mở màn hình luyện tập |
| `README.md` | Không có hướng dẫn chạy AI | Thêm mục chạy tính năng chấm phát âm |

## 4. File mới trong app Flutter

| File | Vai trò |
|---|---|
| `domain/entities/speech_analysis.dart` | Kết quả AI trả về |
| `domain/repositories/speech_analysis_repository.dart` | Giao diện gửi phân tích |
| `domain/repositories/speech_recorder.dart` | Giao diện thu âm |
| `domain/usecases/analyze_pronunciation.dart` | Phân tích, cộng vào phiên trong ngày, lưu kết quả; không lưu lần đọc sai câu |
| `data/datasources/speech_api_client.dart` | Gọi API bằng Dio |
| `data/datasources/wav_speech_recorder.dart` | Thu WAV 16 kHz mono, xin quyền micro |
| `data/models/speech_analysis_model.dart` | Bóc tách JSON, ánh xạ trạng thái |
| `data/repositories/speech_analysis_repository_impl.dart` | Chuyển exception thành `Failure` |
| `presentation/controllers/practice_controller.dart` | Trạng thái thu âm, tự dừng ở 29 giây |
| `presentation/screens/practice_screen.dart` | Màn hình luyện đọc tối thiểu, Quân có thể thay giao diện |
| `test/pronunciation_ai_test.dart` | 19 test mới |

## 5. Module AI

| Thành phần | Ban đầu (`F:\TH3`) | Hiện tại (`ai_server/`) |
|---|---|---|
| Mã AI | `server/ai/` | `ai/` |
| Test | `test/ai.test.js` | `test/ai.test.js`, thêm `test/api.test.js` |
| Công cụ đánh giá | `scripts/evaluate-voices.js` | Cùng tên, thêm lệnh `fluency` |
| Tài liệu | `docs/` | `docs/`, cập nhật API, bảng lỗi và kết quả đo lưu loát |
| Khởi động dịch vụ | `server/index.js` chưa tồn tại | Thêm `index.js`, `app.js`. Mặc định lắng nghe `127.0.0.1:8787` |
| Tên gói | `speakstreak` | `articulation-ai-server` |
| Thư viện | Có `web-push`, `puppeteer-core` | Đã bỏ vì không dùng |
| `ai/wav.js` | Tính năng lượng khung nằm trong `measureSpeech` | Tách thành `frameEnergies`, `voicedThreshold` để dùng chung, kết quả không đổi |
| `ai/scorer.js` | Từ không có gợi ý | Thêm `suggestion`, dựa trên âm bị điểm thấp nhất |
| `ai/index.js` | Không có `fluency` | Trả thêm `fluency` |
| `ai/fluency.js` | Chưa có | File mới tính điểm lưu loát |
| Mô hình, dữ liệu đánh giá | `.models/`, `.eval-data/` | Đã chép, nằm trong `.gitignore`, không vào commit |
| Giao tiếp với app | Chỉ là thư viện | `GET /api/health`, `POST /api/pronunciation/analyze` |
| Điểm lưu loát | Không có | Có `fluency`, không tính vào `overall` |
| Gợi ý | Chỉ ở cấp cả câu | Thêm `suggestion` cho từng từ |
| Điểm `overall` | | Giữ nguyên, các số liệu đánh giá cũ vẫn đúng |

Thư mục gốc `F:\TH3` không bị sửa.

### Ánh xạ trạng thái

| AI trả về | Giá trị trong app | Ghi chú |
|---|---|---|
| Từ `spoken = false` | `missed` | |
| Từ `poor`, `fair` | `wrong` | Lỗi `uncertain` có gợi ý ghi "có thể chưa chuẩn", nhưng vẫn hiện màu đỏ vì UI chỉ có 3 trạng thái |
| Từ `good` | `correct` | |
| Âm `correct`, `close` | `correct` | |
| Âm `wrong` | `mispronounced` | |
| Âm `missing` | `omitted` | |

## 6. Vấn đề đã xử lý

| # | Vấn đề | Cách xử lý | Trạng thái |
|---|---|---|---|
| 1 | Mapper ghi JSON theo âm vị, màn hình Quân đọc theo từ | Đổi sang JSON theo từ. Dữ liệu từ máy chủ thật đọc được 12/12 từ | Xong |
| 2 | `record 5.2.1` xung đột `record_linux`, không biên dịch được khi import | Nâng lên `record 7.1.2` | Xong |
| 3 | `flutter_local_notifications` đòi desugaring, app không build được APK | Bật desugaring | Xong |
| 4 | Thiếu `dio` | Đã thêm | Xong |
| 5 | Android chặn `http://` | Đã cho phép | Xong, nhưng áp dụng cả bản release |
| 6 | Khóa ngoại `session_id` | Tự tạo hoặc cộng dồn phiên trong ngày | Xong |
| 7 | Thanh "Lưu loát" sẽ luôn là 0 | Thêm điểm `fluency` | Xong, công thức chưa kiểm chứng |
| 8 | Ngưỡng lưu loát đầu tiên khiến ai cũng được 100 | Đo lại trên L2-ARCTIC và dời mốc từ 7 lên 9 âm/giây | Xong |

## 7. Còn tồn tại

| # | Vấn đề | Người phù hợp |
|---|---|---|
| 1 | Chưa chạy trên Android, nên ghi âm bằng micro thật chưa được kiểm chứng | Tùng, Thuận (checklist 7) |
| 2 | Chưa thử với người Việt và nhiều người dùng thật. Đây là yêu cầu của đề bài | Thuận (checklist 7) |
| 3 | Streak trong bảng `User` chưa cập nhật sau khi luyện. App đã ghi `PracticeSession` | Hiếu |
| 4 | Chưa có bài luyện khớp mã `drill-*`. App chỉ hiện tên lỗi và lời khuyên | Thuận, Quân |
| 5 | Lỗi `uncertain` vẫn hiện màu đỏ vì giao diện chỉ có 3 trạng thái | Quân |
| 6 | README ghi phân công thư mục mâu thuẫn với bảng thành viên | Nhóm |
| 7 | App cần máy chủ AI đang chạy, không có mạng thì không chấm được. API không có xác thực | Nhóm |
| 8 | Gói `speech_to_text` trong `pubspec.yaml` không được dùng, vì mô hình phía máy chủ đã nhận dạng âm vị | Nhóm |
| 9 | Điểm lưu loát dùng công thức tự đặt, chưa có nhãn của người để kiểm chứng. Người mới học có thể bị điểm thấp | Tùng, Thuận (checklist 7) |

Trên máy có pub cache và dự án ở hai ổ đĩa khác nhau, ví dụ C và F, cần build bằng lệnh sau. Đây là lỗi môi trường nên không ghi vào cấu hình chung:

```bash
flutter build apk --debug --android-project-arg=kotlin.incremental=false
```

## 8. Commit

Dùng lệnh sau để đưa lên nhánh riêng. Không chỉ định tên nhánh thì lệnh push sẽ bị từ chối vì nhánh chưa có upstream.

```bash
git add .
git commit -m "Tích hợp ghi âm và AI chấm phát âm"
git push -u origin feature/hoangtung
```
