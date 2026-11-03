# Dịch vụ AI phân tích phát âm

Mục (3) và (4) của Hoàng Tùng. Thư viện chấm điểm nằm trong `ai/`, `app.js` bọc thành API HTTP cho app Flutter.

## Chạy dịch vụ

```bash
cd ai_server
npm install
npm start        # lần đầu tải mô hình khoảng 320 MB về .models/
```

| Biến môi trường | Mặc định | Ý nghĩa |
|---|---|---|
| `PORT` | `8787` | Cổng lắng nghe |
| `HOST` | `127.0.0.1` | Máy ảo Android gọi được qua `10.0.2.2`. Điện thoại thật cần `0.0.0.0` |

API không có xác thực và dùng HTTP không mã hóa. Với `HOST=0.0.0.0`, mọi máy cùng mạng đều gọi được,
nên chỉ dùng trên mạng tin cậy để phát triển và kiểm thử.

Trỏ app tới máy tính khi dùng điện thoại thật:

```bash
flutter run --dart-define=AI_SERVER_URL=http://<ip-máy-tính>:8787
```

## API

| Phương thức | Đường dẫn | Mô tả |
|---|---|---|
| `GET` | `/api/health` | `{ status, model: { state, failure } }` |
| `POST` | `/api/pronunciation/analyze?text=<câu mục tiêu>` | Thân là WAV, `Content-Type: audio/wav`, tối đa 2 MB. Trả về JSON ở mục "Kết quả trả về" |

Lỗi có dạng `{ "error": { "code", "message", "words" } }`, trong đó `message` là tiếng Việt, hiển thị được cho người dùng.

## Cách hoạt động

1. **Nhận dạng âm vị** (`recognizer.js`): mô hình wav2vec2 `onnx-community/wav2vec2-lv-60-espeak-cv-ft-ONNX`
   chạy cục bộ, trả về âm nghe được dưới dạng IPA. Âm thanh không rời khỏi máy chủ.
2. **Quy về một bộ âm** (`phonemes.js`): IPA của mô hình và CMUdict được đưa về ARPAbet 39 âm.
3. **Căn chỉnh** (`aligner.js`): quy hoạch động Needleman-Wunsch theo từ, chọn cách đọc khớp nhất trong từ điển.
4. **Chấm điểm** (`similarity.js`, `scorer.js`): điểm câu, từ, âm vị. Chấp nhận biến thể tự nhiên
   (âm vỗ /ɾ/, nguyên âm rút gọn, bỏ /h/ ở từ chức năng).
5. **Kiểm tra đối lập**: với /ð/, /θ/, /v/, so xác suất của âm chuẩn và âm đối lập, vì mô hình hay "sửa hộ".
6. **Phản hồi** (`feedback.js`): gom lỗi thành nhận xét tiếng Việt kèm mã bài tập gợi ý.

## Dùng trực tiếp thư viện

```js
import { analyzeSpeech, createRecognizer } from './ai/index.js';

const recognizer = createRecognizer({ cacheDir: '.models' });
recognizer.preload(); // Lần đầu tải khoảng 320 MB, sau đó nạp từ đĩa
const result = await analyzeSpeech({ wav, text: 'I think so.', recognizer });
```

`wav` là `Buffer` chứa WAV PCM 16-bit hoặc float 32-bit, dài 0,3 đến 30 giây. Nên gửi mono 16 kHz.
Tần số khác được chuyển mẫu tuyến tính, không có lọc chống răng cưa, nên chất lượng thấp hơn.

`recognizer.status()` trả về `{ state: 'idle' | 'loading' | 'ready' | 'failed', failure }`.

### Kết quả trả về

```jsonc
{
  "text": "I think so.",
  "overall": 88,             // 0..100
  "accuracy": 86,            // % âm đúng hoàn toàn
  "completeness": 100,       // % từ đã được nói
  "fluency": 100,            // 0..100, từ tốc độ nói và khoảng ngừng; không tính vào overall
  "offTarget": false,        // true: gần như đọc câu khác, không nên tính là một lần luyện
  "noisy": false,            // true: nền ồn, nên báo người dùng rằng điểm có thể thấp oan
  "verdict": { "level": "good", "message": "..." }, // excellent | good | fair | needs-work
  "heardIpa": "aɪ θ ɪ ŋ k s oʊ",
  "audioMs": 1500,
  "engine": "onnx-community/wav2vec2-lv-60-espeak-cv-ft-ONNX",
  "words": [{
    "word": "think", "score": 75, "status": "fair", // good | fair | poor
    "spoken": true, "expectedIpa": "θɪŋk", "heardIpa": "tɪŋk", "extras": 0,
    "suggestion": "...",     // null nếu từ đạt "good"
    "phonemes": [{
      "position": 0, "expected": "TH", "heard": "T",
      "expectedIpa": "θ", "heardIpa": "t",
      "score": 0.25,
      "status": "wrong",     // correct | close | wrong | missing
      "uncertain": false     // true: nên hiển thị "có thể chưa chuẩn", không kết luận là sai
    }]
  }],
  "issues": [{               // tối đa 4, lỗi nhiều nhất trước
    "key": "th-voiceless", "title": "Âm /θ/ (think, three)", "tip": "...",
    "drill": "drill-th-voiceless", "count": 1,
    "examples": [{ "word": "think", "expected": "θ", "heard": "t" }]
  }]
}
```

### Lỗi cần xử lý

| Mã `code` trong API | Ý nghĩa | HTTP |
|---|---|---|
| `BAD_TEXT` | Thiếu câu mục tiêu hoặc dài quá 1000 ký tự | 400 |
| `BAD_AUDIO` | Không phải WAV hợp lệ, hoặc sai `Content-Type` | 400, 415 |
| `TOO_LARGE` | Thân yêu cầu quá 2 MB | 413 |
| `TOO_SHORT`, `TOO_LONG`, `NO_SPEECH` | Cần ghi âm lại | 422 |
| `UNKNOWN_WORDS`, kèm `words` | Từ không có trong CMUdict | 422 |
| `EMPTY_TARGET` | Câu không có từ tiếng Anh | 422 |
| `MODEL_BUSY` | Hàng đợi đầy (quá 8 yêu cầu) | 503 |
| `MODEL_UNAVAILABLE` | Mô hình chưa tải được | 503 |
| `INTERNAL` | Lỗi khác của máy chủ | 500 |

Mã bài tập trong `issues[].drill`: `drill-th-voiceless`, `drill-th-voiced`, `drill-final-s`,
`drill-final-consonants`, `drill-clusters`, `drill-r-l`, `drill-s-sh`, `drill-ch-j`, `drill-v-f`,
`drill-long-short-i`, `drill-ae-eh`, `drill-long-short-u`, `drill-diphthongs`.
Dữ liệu bài học (`seed_data.dart`) chưa có các bài này, nên app hiện chỉ hiển thị tên lỗi và lời khuyên, chưa mở được bài luyện.

## Kết quả kiểm thử

Chạy `npm test` (unit test) và `npm run eval` (đánh giá, cần dữ liệu trong `.eval-data/`).
Số liệu đầy đủ ở `docs/ai-evaluation.json`.

### Giọng người học thật, so với nhãn của người (L2-ARCTIC)

447 câu, 14.682 âm vị, 3 người nói (2 tiếng Ả Rập, 1 tiếng Hindi). Người gán nhãn đánh dấu 4,5% số âm là lỗi.
Ngưỡng chọn trên 2 người, đo trên người còn lại:

| Cấu hình | Precision | Recall | F1 | Báo nhầm | Tương quan điểm câu |
|---|---:|---:|---:|---:|---:|
| Không kiểm tra đối lập | 24,5% | 22,8% | 23,6% | 2,8% | 0,14 |
| **Có kiểm tra đối lập (đang dùng)** | **29,1%** | **49,4%** | **36,6%** | **4,9%** | **0,24** |

Điểm trung bình: 92,2 so với 93,8 của nhãn người.

### Giọng bản ngữ thật (LibriSpeech)

54 câu của **1 người nói**. Điểm trung bình 95, thấp nhất 78; 2,2% số từ bị xếp "poor".

### Giọng tổng hợp (Windows David, Zira)

| Điều kiện | Điểm trung bình khi đọc đúng | Thấp nhất | Bị cảnh báo ồn |
|---|---:|---:|---:|
| Tốc độ thường | 97,1 | 91 | 0/16 |
| Đọc chậm | 96,8 | 87 | 0/16 |
| Đọc nhanh | 95,6 | 88 | 0/16 |
| Nhiễu 20 dB | 95,6 | 88 | 0/16 |
| Nhiễu 10 dB | 88,2 | 64 | 16/16 |
| Nhiễu 5 dB | 59,5 | 40 | 16/16 |

Cấy lỗi có chủ đích (18 câu): 97,7% số từ cấy lỗi bị đánh dấu, 100% câu nêu đúng loại lỗi.

### Điểm lưu loát (`fluency`)

Công thức tự đặt, **chưa có nhãn của người để kiểm chứng**. Đủ 100 điểm từ 9 âm/giây, giảm dần về 40 điểm ở 4 âm/giây.
Trừ 12 điểm cho mỗi khoảng ngừng từ 0,35 giây, được miễn 1 khoảng ngừng trên mỗi 20 âm.
Bài dưới 10 âm chỉ xét khoảng ngừng, vì đọc riêng một từ thường kéo dài âm.

Chạy `npm run eval -- fluency`:

| Dữ liệu | Thấp nhất | Phân vị 10 | Trung vị |
|---|---:|---:|---:|
| L2-ARCTIC, 447 câu | 73 | 94 | 100 |
| L2-ARCTIC, chèn 2 khoảng lặng 0,8 giây | 52 | 76 | 88 |
| Giọng tổng hợp đọc chậm | 84 | 86 | 100 |
| Giọng tổng hợp tốc độ thường, đọc nhanh | 100 | 100 | 100 |

Ngưỡng chọn theo người đọc khá trôi chảy, nên người mới học có thể bị điểm thấp.
Điểm này không thưởng cho việc đọc quá nhanh và không đo nhịp điệu.

### Phát hiện đọc sai câu (`offTarget`)

So đoạn ghi âm với chính câu đó (447 lần) và với câu khác (1.341 lần), ngưỡng hiện tại là 45 điểm:

| | Thấp nhất | Trung vị | Cao nhất | Kết quả ở ngưỡng 45 |
|---|---:|---:|---:|---:|
| Đọc đúng câu | 55 | 94 | 100 | 0/447 bị từ chối oan |
| Đọc câu khác | 11 | 36 | 56 | 113/1.341 (8,4%) vẫn lọt |

Dữ liệu này là câu dài của người đọc khá trôi chảy, nên chưa biết ngưỡng có phù hợp với câu ngắn
hoặc người mới học hay không. Ở nhiễu 5 dB, điểm đọc đúng có thể xuống 40 và bị từ chối.

## Giới hạn đã biết

- **Chưa kiểm thử với người Việt.** Bộ dữ liệu có nhãn chỉ có người Ả Rập và Hindi. Quy tắc lỗi cho người Việt
  dựa trên lỗi phổ biến, chưa được đo. Đây là thiếu sót lớn nhất so với yêu cầu đề bài.
- **Ít người nói.** Tổng cộng 4 người thật và 2 giọng tổng hợp. Danh sách /ð/, /θ/, /v/ được chọn trên cùng
  3 người nói đó, nên F1 36,6% có thể hơi lạc quan.
- **Phát hiện lỗi từng âm chưa đủ tin cậy để kết luận.** Khoảng 7/10 âm bị báo lỗi không trùng với nhãn người.
  Nhãn người cũng có sai số nên con số này là giới hạn dưới thận trọng, nhưng không nên trình bày kết quả
  như một phán quyết tuyệt đối.
- **Điểm câu tương quan yếu với nhãn người (0,24).** Điểm phù hợp để theo dõi xu hướng và khuyến khích luyện tập,
  không phù hợp để đánh giá trình độ.
- **/θ/, /ð/ với giọng tổng hợp:** câu đọc đúng cũng bị trừ điểm (khoảng 86), gần bằng câu đọc sai.
  Đây là lý do có cờ `uncertain`.
- **Môi trường ồn:** dưới khoảng 10 dB điểm giảm mạnh dù đọc đúng; cờ `noisy` chỉ cảnh báo, không sửa được điểm.
- **Từ ngoài CMUdict** (tên riêng hiếm, từ mới) không chấm được và bị từ chối.
- **Nhịp điệu, trọng âm câu, ngữ điệu** chưa được đánh giá.
- **Giấy phép dữ liệu:** bản L2-ARCTIC gốc cấm dùng thương mại (CC BY-NC 4.0 theo trang KoelLabs/L2Arctic).
  `.eval-data/` chỉ dùng để đánh giá, không đóng gói vào sản phẩm.
