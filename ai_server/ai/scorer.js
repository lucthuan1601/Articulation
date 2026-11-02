// Chấm điểm: nhận chuỗi âm nghe được và câu mục tiêu, trả về điểm theo câu, từ và âm vị.
import { alignWords } from './aligner.js';
import { buildIssues, classifyError, verdictFor } from './feedback.js';
import { isVowel, phonemeIpa, pronunciationIpa, textToTarget } from './phonemes.js';
import { contrastCompetitor, DEFAULT_CONTRAST_MARGIN, phonemeScore } from './similarity.js';

const EXTRA_PHONEME_WEIGHT = 0.25;
// Đo trên L2-ARCTIC: đọc đúng câu thấp nhất 55, đọc câu khác trung vị 36 (docs/ai-module.md).
// Để dưới mức tách tốt nhất vì người mới học sẽ có điểm thấp hơn người trong bộ dữ liệu.
const OFF_TARGET_SCORE = 45;
const GOOD_WORD_SCORE = 85;

function phonemeStatus(score, heard) {
  if (score >= 0.99) return 'correct';
  if (score >= 0.5) return 'close';
  return heard ? 'wrong' : 'missing';
}

// Nếu mô hình chọn đúng âm chuẩn nhưng âm đối lập cũng có xác suất cao, coi như nghe thành âm đối lập.
export function resolveHeard(pair, evidence, margin = DEFAULT_CONTRAST_MARGIN) {
  if (pair.heard !== pair.phoneme || !evidence) return pair.heard;
  return contrastCompetitor(pair.phoneme, evidence[pair.heardIndex], margin) ?? pair.heard;
}

function wordStatus(score) {
  if (score >= GOOD_WORD_SCORE) return 'good';
  return score >= 60 ? 'fair' : 'poor';
}

// Gợi ý cho từ cần luyện lại, dựa trên âm bị điểm thấp nhất.
function wordSuggestion(score, spoken, phonemes) {
  if (score >= GOOD_WORD_SCORE) return null;
  if (!spoken) return 'Bạn chưa đọc từ này. Hãy nghe mẫu rồi đọc lại cả câu.';
  const worst = phonemes.filter((p) => p.status !== 'correct').sort((a, b) => a.score - b.score)[0];
  if (!worst) return null;
  const { tip } = classifyError(worst.expected, worst.heard, worst);
  return worst.uncertain ? `Âm /${worst.expectedIpa}/ có thể chưa chuẩn. ${tip}` : tip;
}

function isConsonantAt(pairs, index) {
  return index >= 0 && index < pairs.length && !isVowel(pairs[index].phoneme);
}

function scoreWord(aligned, evidence, margin) {
  const { pairs, extras } = aligned;
  const spokenAtAll = pairs.some((pair) => pair.heard);
  const phonemes = pairs.map((pair, index) => {
    const heard = resolveHeard(pair, evidence, margin);
    // Nới lỏng âm rút gọn chỉ áp dụng khi từ thực sự được nói.
    const score = spokenAtAll ? phonemeScore(pair.phoneme, heard, pair.stress) : 0;
    return {
      position: index,
      expected: pair.phoneme,
      heard,
      expectedIpa: phonemeIpa(pair.phoneme, pair.stress),
      heardIpa: phonemeIpa(heard),
      score,
      status: phonemeStatus(score, heard),
      // Lỗi suy ra từ kiểm tra đối lập, không phải từ âm mô hình chọn: giao diện nên nói "có thể chưa chuẩn".
      uncertain: heard !== pair.heard,
      wordFinal: index === pairs.length - 1,
      inCluster: isConsonantAt(pairs, index - 1) || isConsonantAt(pairs, index + 1),
    };
  });
  const earned = phonemes.reduce((sum, p) => sum + p.score, 0);
  const denominator = phonemes.length + extras.length * EXTRA_PHONEME_WEIGHT;
  const score = Math.round((earned / denominator) * 100);
  const spoken = phonemes.some((p) => p.heard);
  return {
    word: aligned.word,
    score,
    status: wordStatus(score),
    spoken,
    expectedIpa: pronunciationIpa(aligned.variant),
    heardIpa: pairsToIpa(phonemes, extras),
    suggestion: wordSuggestion(score, spoken, phonemes),
    phonemes,
    earned,
    denominator,
    extras: extras.length,
  };
}

function pairsToIpa(phonemes, extras) {
  return phonemes.map((p) => p.heardIpa).join('') + extras.map((p) => phonemeIpa(p)).join('');
}

// Kiểm tra câu mục tiêu trước khi tốn thời gian chạy mô hình.
export function prepareTarget(text) {
  const { words, unknown } = textToTarget(text);
  if (unknown.length > 0) {
    const error = new Error(`Không có trong từ điển: ${unknown.join(', ')}`);
    error.code = 'UNKNOWN_WORDS';
    error.words = unknown;
    throw error;
  }
  if (words.length === 0) {
    const error = new Error('Câu mục tiêu không có từ tiếng Anh nào');
    error.code = 'EMPTY_TARGET';
    throw error;
  }
  return words;
}

/**
 * @param {string} text câu mục tiêu
 * @param {string[]} heard chuỗi ARPAbet nghe được
 * @param {Object<string, number>[]} [evidence] xác suất các âm tại từng vị trí của `heard`
 * @param {number} [margin] ngưỡng log-xác suất của kiểm tra đối lập
 */
export function scorePronunciation(text, heard, evidence = null, margin = DEFAULT_CONTRAST_MARGIN) {
  const words = prepareTarget(text);
  const alignment = alignWords(words, heard);
  const scored = alignment.words.map((word) => scoreWord(word, evidence, margin));
  const earned = scored.reduce((sum, w) => sum + w.earned, 0);
  const denominator = scored.reduce((sum, w) => sum + w.denominator, 0)
    + (alignment.leading.length + alignment.trailing.length) * EXTRA_PHONEME_WEIGHT;
  const total = scored.reduce((sum, w) => sum + w.phonemes.length, 0);
  const correct = scored.reduce((sum, w) => sum + w.phonemes.filter((p) => p.status === 'correct').length, 0);
  const overall = Math.round((earned / denominator) * 100);

  const errors = scored.flatMap((w) => w.phonemes
    .filter((p) => p.status !== 'correct')
    .map((p) => ({ ...p, word: w.word })));

  const result = {
    text,
    overall,
    accuracy: Math.round((correct / total) * 100),
    completeness: Math.round((scored.filter((w) => w.spoken).length / scored.length) * 100),
    offTarget: overall < OFF_TARGET_SCORE,
    verdict: verdictFor(overall),
    heardIpa: heard.map((p) => phonemeIpa(p)).join(' '),
    words: scored.map(({ earned: _e, denominator: _d, ...word }) => ({
      ...word,
      phonemes: word.phonemes.map(({ wordFinal: _w, inCluster: _c, ...p }) => p),
    })),
    issues: buildIssues(errors),
  };
  return result;
}
