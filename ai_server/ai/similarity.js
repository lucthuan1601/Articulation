// Điểm tương đồng giữa âm chuẩn và âm nghe được, thang 0..1.
// Ngưỡng ở đây quyết định điều gì là lỗi: các biến thể tự nhiên của người bản ngữ được 1 điểm,
// còn lỗi điển hình của người học (ví dụ /θ/ -> /t/) phải bị đánh dấu dù hai âm khá giống nhau.
import { isVowel } from './phonemes.js';

const pairKey = (a, b) => (a < b ? `${a}|${b}` : `${b}|${a}`);

function pairs(list, score) {
  return list.map(([a, b]) => [pairKey(a, b), score]);
}

const PAIR_SCORES = new Map([
  // Đối lập hữu thanh/vô thanh: gần đúng.
  ...pairs([['P', 'B'], ['T', 'D'], ['K', 'G'], ['S', 'Z'], ['F', 'V'], ['CH', 'JH'], ['SH', 'ZH'], ['TH', 'DH']], 0.5),
  // Nguyên âm và phụ âm cận kề.
  ...pairs([
    ['IY', 'IH'], ['EH', 'AE'], ['UW', 'UH'], ['AH', 'AA'], ['EH', 'EY'], ['OW', 'AO'], ['AE', 'AH'],
    ['AH', 'UH'], ['EH', 'IH'], ['AH', 'EH'], ['AH', 'IH'], ['AY', 'AE'], ['AW', 'AE'], ['OW', 'UH'],
    ['M', 'N'], ['N', 'NG'], ['S', 'SH'], ['Z', 'ZH'], ['CH', 'SH'], ['JH', 'ZH'],
  ], 0.5),
  // Lỗi đặc trưng của người học: còn liên quan nhưng phải bị coi là sai.
  ...pairs([
    ['TH', 'T'], ['TH', 'S'], ['TH', 'F'], ['DH', 'D'], ['DH', 'Z'], ['DH', 'V'], ['L', 'N'], ['L', 'R'],
    ['V', 'B'], ['V', 'W'], ['F', 'P'], ['CH', 'T'], ['JH', 'Z'], ['JH', 'D'],
  ], 0.25),
]);

// Biến thể chấp nhận được ở âm tiết không nhấn: nguyên âm rút gọn thành /ə/ hoặc /ɪ/.
const REDUCED = new Set(['AH', 'IH', 'ER', 'UH']);

// Các cặp người bản ngữ dùng thay thế nhau (hòa nhập cot/caught, âm /i/ cuối từ...).
const FREE_VARIANTS = new Set([pairKey('AA', 'AO')]);

export function similarity(expected, heard, stress = null) {
  if (expected === heard) return 1;
  // Âm vỗ /ɾ/ của tiếng Anh Mỹ là cách đọc bình thường của t/d giữa nguyên âm.
  if (heard === 'DX') return expected === 'T' || expected === 'D' ? 1 : expected === 'R' ? 0.5 : 0;
  if (heard === 'Q') return expected === 'T' ? 0.75 : expected === 'D' ? 0.5 : 0;
  if (FREE_VARIANTS.has(pairKey(expected, heard))) return 1;
  if (stress === 0 && isVowel(expected) && isVowel(heard)) {
    if (REDUCED.has(heard)) return 1;
    if (expected === 'IY' && heard === 'EY') return 0.75;
  }
  return PAIR_SCORES.get(pairKey(expected, heard)) ?? 0;
}

// Nguyên âm rút gọn ở âm tiết không nhấn có thể gần như biến mất khi nói nhanh ("fam(i)ly").
const REDUCED_MISSING_SCORE = 0.75;

export function missingScore(expected, stress = null) {
  return stress === 0 && REDUCED.has(expected) ? REDUCED_MISSING_SCORE : 0;
}

export function phonemeScore(expected, heard, stress = null) {
  return heard ? similarity(expected, heard, stress) : missingScore(expected, stress);
}

// Âm mà mô hình hay "sửa hộ" thành âm chuẩn: kiểm tra thêm xác suất của âm đối lập.
// Chỉ giữ các âm đã có tác dụng khi đo trên người nói không dùng để chọn ngưỡng
// (docs/ai-module.md); thêm /ɹ/, /l/ làm kết quả tệ đi nên không bật.
export const CONTRASTS = { DH: ['D', 'Z'], TH: ['T', 'S', 'F'], V: ['W', 'B'] };
export const DEFAULT_CONTRAST_MARGIN = 5.5;

// Trả về âm đối lập nếu xác suất của nó không kém âm chuẩn đủ xa.
export function contrastCompetitor(expected, evidence, margin = DEFAULT_CONTRAST_MARGIN) {
  const competitors = CONTRASTS[expected];
  if (!competitors || !evidence) return null;
  const expectedLog = Math.log(evidence[expected] ?? 1e-6);
  let best = null;
  let bestLog = -Infinity;
  for (const competitor of competitors) {
    const value = Math.log(evidence[competitor] ?? 1e-6);
    if (value > bestLog) { bestLog = value; best = competitor; }
  }
  return expectedLog - bestLog < margin ? best : null;
}

// Chi phí căn chỉnh: thay thế khác loại (nguyên âm <-> phụ âm) đắt hơn xóa + chèn.
const BASE_DELETE_COST = 0.8;
export const INSERT_COST = 0.6;

export function deleteCost(expected, stress = null) {
  return BASE_DELETE_COST * (1 - missingScore(expected, stress));
}

export function substituteCost(expected, heard, stress = null) {
  const score = similarity(expected, heard, stress);
  if (score > 0) return 1 - score;
  const heardKind = heard === 'DX' || heard === 'Q' ? false : isVowel(heard);
  return isVowel(expected) === heardKind ? 1.0 : 1.6;
}
