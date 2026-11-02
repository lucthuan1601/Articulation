// Biến danh sách lỗi âm vị thành nhận xét và bài tập gợi ý.
import { isVowel } from './phonemes.js';

const RULES = [
  {
    key: 'th-voiceless',
    title: 'Âm /θ/ (think, three)',
    tip: 'Đặt đầu lưỡi nhẹ giữa hai hàm răng rồi thổi hơi. Không bật lưỡi như /t/ và không đọc thành /s/.',
    drill: 'drill-th-voiceless',
    match: (e) => e === 'TH',
  },
  {
    key: 'th-voiced',
    title: 'Âm /ð/ (this, mother)',
    tip: 'Lưỡi đặt giữa hai hàm răng như /θ/ nhưng rung dây thanh. Đừng đọc thành /d/ hoặc /z/.',
    drill: 'drill-th-voiced',
    match: (e) => e === 'DH',
  },
  {
    key: 'final-s',
    title: 'Âm cuối /s/, /z/ (books, dogs)',
    tip: 'Giữ hơi ở cuối từ cho đến khi nghe rõ tiếng xì. Đây là dấu hiệu số nhiều và động từ ngôi thứ ba.',
    drill: 'drill-final-s',
    match: (e, h, ctx) => (e === 'S' || e === 'Z') && ctx.wordFinal && !h,
  },
  {
    key: 'final-consonant',
    title: 'Phụ âm cuối từ',
    tip: 'Tiếng Việt thường nuốt âm cuối, còn tiếng Anh cần phát âm trọn. Hãy khép miệng đúng vị trí và thả nhẹ hơi ở cuối từ.',
    drill: 'drill-final-consonants',
    match: (e, h, ctx) => !isVowel(e) && ctx.wordFinal && !h,
  },
  {
    key: 'cluster',
    title: 'Cụm phụ âm (street, strong)',
    tip: 'Đọc chậm từng phụ âm trong cụm rồi nối dần, không chèn thêm nguyên âm và không bỏ âm nào.',
    drill: 'drill-clusters',
    match: (e, h, ctx) => !isVowel(e) && ctx.inCluster && !h,
  },
  {
    key: 'r-sound',
    title: 'Âm /ɹ/ (right, red)',
    tip: 'Cong đầu lưỡi về sau, không chạm vòm miệng, môi hơi tròn. Khác với /z/ hay /l/.',
    drill: 'drill-r-l',
    match: (e) => e === 'R' || e === 'ER',
  },
  {
    key: 'l-sound',
    title: 'Âm /l/ (light, feel)',
    tip: 'Đầu lưỡi chạm lợi trên, hơi thoát ra hai bên. Ở cuối từ vẫn giữ lưỡi chạm lợi, đừng đọc thành /n/ hay bỏ âm.',
    drill: 'drill-r-l',
    match: (e) => e === 'L',
  },
  {
    key: 'sh-sound',
    title: 'Âm /ʃ/ và /ʒ/ (she, measure)',
    tip: 'Chu môi ra trước, lưỡi lùi hơn so với /s/ và không chạm răng.',
    drill: 'drill-s-sh',
    match: (e) => e === 'SH' || e === 'ZH',
  },
  {
    key: 'ch-jh-sound',
    title: 'Âm /tʃ/ và /dʒ/ (chair, job)',
    tip: 'Bắt đầu bằng cách chặn hơi như /t/ hoặc /d/, rồi xả ra thành /ʃ/ hoặc /ʒ/.',
    drill: 'drill-ch-j',
    match: (e) => e === 'CH' || e === 'JH',
  },
  {
    key: 's-z-sound',
    title: 'Âm /s/ và /z/',
    tip: 'Đầu lưỡi gần lợi trên và tạo khe hẹp. Với /z/, đặt tay lên cổ để cảm nhận độ rung.',
    drill: 'drill-s-sh',
    match: (e) => e === 'S' || e === 'Z',
  },
  {
    key: 'v-f-sound',
    title: 'Âm /v/ và /f/ (very, fine)',
    tip: 'Răng trên chạm nhẹ môi dưới. /v/ rung dây thanh, không đọc thành /b/ hay /w/.',
    drill: 'drill-v-f',
    match: (e) => e === 'V' || e === 'F',
  },
  {
    key: 'long-short-i',
    title: 'Phân biệt /iː/ và /ɪ/ (sheep, ship)',
    tip: '/iː/ căng môi và kéo dài; /ɪ/ ngắn, lỏng hơn, miệng hơi mở.',
    drill: 'drill-long-short-i',
    match: (e) => e === 'IY' || e === 'IH',
  },
  {
    key: 'ae-eh',
    title: 'Phân biệt /æ/ và /ɛ/ (bad, bed)',
    tip: '/æ/ mở miệng rộng hơn, hàm dưới hạ xuống; /ɛ/ mở vừa.',
    drill: 'drill-ae-eh',
    match: (e) => e === 'AE' || e === 'EH',
  },
  {
    key: 'long-short-u',
    title: 'Phân biệt /uː/ và /ʊ/ (food, good)',
    tip: '/uː/ tròn môi, căng và dài; /ʊ/ ngắn và lỏng hơn.',
    drill: 'drill-long-short-u',
    match: (e) => e === 'UW' || e === 'UH',
  },
  {
    key: 'diphthong',
    title: 'Nguyên âm đôi (day, go, my)',
    tip: 'Trượt rõ từ âm đầu sang âm sau, đừng giữ một nguyên âm phẳng.',
    drill: 'drill-diphthongs',
    match: (e) => ['EY', 'OW', 'AY', 'AW', 'OY'].includes(e),
  },
  {
    key: 'vowel',
    title: 'Nguyên âm',
    tip: 'Nghe lại câu mẫu và chú ý độ mở miệng, vị trí lưỡi và độ dài của nguyên âm.',
    drill: 'drill-diphthongs',
    match: (e) => isVowel(e),
  },
  {
    key: 'consonant',
    title: 'Phụ âm',
    tip: 'Nghe lại câu mẫu, đọc chậm từng từ và chú ý vị trí của lưỡi và môi.',
    drill: 'drill-final-consonants',
    match: () => true,
  },
];

export const ISSUE_KEYS = RULES.map((rule) => rule.key);
export const DRILL_SLUGS = [...new Set(RULES.map((rule) => rule.drill))];

export function classifyError(expected, heard, context) {
  return RULES.find((rule) => rule.match(expected, heard, context));
}

// Gom lỗi theo quy tắc; quy tắc lỗi nhiều nhất đứng trước.
export function buildIssues(errors) {
  const grouped = new Map();
  for (const error of errors) {
    const rule = classifyError(error.expected, error.heard, error);
    const issue = grouped.get(rule.key) ?? {
      key: rule.key, title: rule.title, tip: rule.tip, drill: rule.drill, count: 0, examples: [],
    };
    issue.count += 1;
    if (!issue.examples.some((ex) => ex.word === error.word)) {
      issue.examples.push({ word: error.word, expected: error.expectedIpa, heard: error.heardIpa });
    }
    grouped.set(rule.key, issue);
  }
  return [...grouped.values()].sort((a, b) => b.count - a.count).slice(0, 4);
}

export function verdictFor(score) {
  if (score >= 90) return { level: 'excellent', message: 'Xuất sắc! Phát âm của bạn rất rõ và chuẩn.' };
  if (score >= 75) return { level: 'good', message: 'Tốt lắm. Chỉ còn một vài âm cần chỉnh lại.' };
  if (score >= 50) return { level: 'fair', message: 'Khá ổn. Hãy tập trung vào các âm được đánh dấu rồi thử lại.' };
  return { level: 'needs-work', message: 'Chưa rõ lắm. Hãy nghe mẫu, đọc chậm hơn và thử lại.' };
}
