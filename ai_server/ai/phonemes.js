// Bảng âm vị dùng chung. Mọi so sánh đều diễn ra trên bộ ARPAbet 39 âm của CMUdict;
// đầu ra IPA của mô hình được quy về bộ này (cộng hai ký hiệu phụ DX và Q).
import { dictionary } from 'cmu-pronouncing-dictionary';

export const IPA = {
  AA: 'ɑ', AE: 'æ', AH: 'ʌ', AO: 'ɔ', AW: 'aʊ', AY: 'aɪ', B: 'b', CH: 'tʃ', D: 'd', DH: 'ð',
  EH: 'ɛ', ER: 'ɝ', EY: 'eɪ', F: 'f', G: 'ɡ', HH: 'h', IH: 'ɪ', IY: 'i', JH: 'dʒ', K: 'k',
  L: 'l', M: 'm', N: 'n', NG: 'ŋ', OW: 'oʊ', OY: 'ɔɪ', P: 'p', R: 'ɹ', S: 's', SH: 'ʃ',
  T: 't', TH: 'θ', UH: 'ʊ', UW: 'u', V: 'v', W: 'w', Y: 'j', Z: 'z', ZH: 'ʒ',
  DX: 'ɾ', Q: 'ʔ',
};

export const VOWELS = new Set(['AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER', 'EY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW']);

export const isVowel = (p) => VOWELS.has(p);

// Token của mô hình espeak -> một hoặc nhiều âm ARPAbet.
const TOKEN_MAP = {
  n: ['N'], s: ['S'], t: ['T'], 'ə': ['AH'], l: ['L'], a: ['AE'], i: ['IY'], k: ['K'], d: ['D'],
  m: ['M'], 'ɛ': ['EH'], 'ɾ': ['DX'], e: ['EY'], 'ɪ': ['IH'], p: ['P'], o: ['OW'], 'ɐ': ['AH'],
  z: ['Z'], 'ð': ['DH'], f: ['F'], j: ['Y'], v: ['V'], b: ['B'], 'ɹ': ['R'], 'ʁ': ['R'], 'ʊ': ['UH'],
  'iː': ['IY'], r: ['R'], w: ['W'], 'ʌ': ['AH'], u: ['UW'], 'ɡ': ['G'], 'æ': ['AE'], 'aɪ': ['AY'],
  'ʃ': ['SH'], h: ['HH'], 'ɔ': ['AO'], 'ɑː': ['AA'], 'ŋ': ['NG'], 'ɚ': ['ER'], 'eɪ': ['EY'],
  'β': ['V'], 'uː': ['UW'], y: ['UW'], 'oʊ': ['OW'], 'ᵻ': ['IH'], 'eː': ['EY'], 'θ': ['TH'],
  'aʊ': ['AW'], ts: ['T', 'S'], 'oː': ['OW'], 'ɣ': ['G'], 'ɜ': ['ER'], 'ɑ': ['AA'], 'dʒ': ['JH'],
  'əl': ['AH', 'L'], x: ['HH'], 'ɜː': ['ER'], 'ç': ['HH'], 'ʒ': ['ZH'], 'tʃ': ['CH'], 'ɔː': ['AO'],
  'ɑːɹ': ['AA', 'R'], 'ɔːɹ': ['AO', 'R'], 'oːɹ': ['AO', 'R'], 'ʋ': ['V'], 'aː': ['AA'], 'ʔ': ['Q'],
  'iə': ['IY', 'AH'], 'ɨ': ['IH'], 'ɛɹ': ['EH', 'R'], 'ɪɹ': ['IH', 'R'], 'ʊɹ': ['UH', 'R'],
  'ɔɪ': ['OY'], 'oɪ': ['OY'], 'aɪɚ': ['AY', 'ER'], 'aɪə': ['AY', 'AH'], 'ju': ['Y', 'UW'],
  'ɪu': ['Y', 'UW'], 'iʊ': ['Y', 'UW'], 'ɒ': ['AA'], 'n̩': ['AH', 'N'], 'l̩': ['AH', 'L'], 'ɫ': ['L'], 'əʊ': ['OW'], 'eə': ['EH'],
  'ɵ': ['AH'], 'ʊə': ['UH', 'AH'], 'ɾ̃': ['DX'], 'ɯ': ['UH'], 'œ': ['EH'], 'ø': ['EH'],
  'ɲ': ['N'], 'ɕ': ['SH'], 'ʑ': ['ZH'], 'ʂ': ['SH'], 'ʐ': ['ZH'], 'tɕ': ['CH'], 'dʑ': ['JH'],
  dZ: ['JH'], tS: ['CH'], S: ['SH'], 'ɟ': ['JH'], c: ['CH'], 'ɻ': ['R'], 'ʎ': ['L'], 'ɭ': ['L'],
  'ɬ': ['L'], 'ɖ': ['D'], 'ʈ': ['T'], 'ɽ': ['DX'], 'ɳ': ['N'], 'ɴ': ['NG'], q: ['K'], 'ʝ': ['Y'],
  'χ': ['HH'], 'ħ': ['HH'], 'ʕ': ['HH'], 'ɸ': ['F'], X: ['HH'],
};

// Bỏ dấu phụ, số thanh điệu, ký hiệu trường âm của các token thuộc ngôn ngữ khác.
function stripToken(token) {
  return token
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[0-9.ːʲʰˤ^\[:"]/g, '');
}

export function heardToken(token) {
  if (TOKEN_MAP[token]) return TOKEN_MAP[token];
  const stripped = stripToken(token);
  if (TOKEN_MAP[stripped]) return TOKEN_MAP[stripped];
  // Âm đôi hai ký tự kiểu "th", "kh", "pː": lấy phụ âm gốc.
  if (stripped.length > 1 && TOKEN_MAP[stripped[0]] && 'hː'.includes(stripped[1])) return TOKEN_MAP[stripped[0]];
  return [];
}

// Mô hình đôi khi tách nguyên âm đôi thành hai token liền nhau; gộp lại trước khi so sánh.
const MERGES = [
  [['ɔ', 'ɔː', 'o', 'oː'], ['ɪ', 'i'], 'OY'],
  [['a', 'æ', 'aː'], ['ɪ', 'i'], 'AY'],
  [['a', 'æ', 'aː'], ['ʊ', 'u'], 'AW'],
  [['e', 'eː', 'ɛ'], ['ɪ', 'i'], 'EY'],
  [['o', 'oː', 'ə'], ['ʊ', 'u'], 'OW'],
];
const R_COLOR_FIRST = ['ə', 'ɜ', 'ɜː', 'ʌ'];
const R_TOKENS = ['ɹ', 'r', 'ɚ'];

function mergedPhoneme(current, next, afterNext) {
  for (const [first, second, phoneme] of MERGES) {
    if (first.includes(current) && second.includes(next)) return phoneme;
  }
  // "ə ɹ" trước nguyên âm là âm /ɹ/ mở đầu từ sau ("a red"), không phải /ɝ/.
  if (R_COLOR_FIRST.includes(current) && R_TOKENS.includes(next)) {
    const following = afterNext ? heardToken(afterNext)[0] : null;
    if (!following || !VOWELS.has(following)) return 'ER';
  }
  return null;
}

/** Trả về các âm nghe được; `sources` là chỉ số token sinh ra âm đó. */
export function tokensToHeard(tokens) {
  const heard = [];
  for (let i = 0; i < tokens.length; i++) {
    const merged = mergedPhoneme(tokens[i], tokens[i + 1], tokens[i + 2]);
    if (merged) {
      heard.push({ phoneme: merged, sources: [i, i + 1] });
      i += 1;
    } else {
      for (const phoneme of heardToken(tokens[i])) heard.push({ phoneme, sources: [i] });
    }
  }
  return heard;
}

export function tokensToPhonemes(tokens) {
  return tokensToHeard(tokens).map((item) => item.phoneme);
}

// Chuẩn hóa từ theo khóa của CMUdict.
export function normalizeWord(word) {
  return word.toLowerCase().replace(/[’`]/g, "'").replace(/^'+|'+$/g, '');
}

export function tokenizeText(text) {
  return (text.match(/[A-Za-z]+(?:['’][A-Za-z]+)*/g) ?? []).map((raw) => ({ raw, key: normalizeWord(raw) }));
}

function parsePronunciation(pron) {
  return pron.split(' ').map((symbol) => {
    const match = symbol.match(/^([A-Z]+)([012])?$/);
    return { phoneme: match[1], stress: match[2] === undefined ? null : Number(match[2]) };
  });
}

// Từ chức năng mà người bản ngữ thường bỏ /h/ khi nói liền mạch.
const WEAK_H_WORDS = new Set(['he', 'him', 'his', 'her', 'hers', 'have', 'has', 'had']);

export function pronunciations(word) {
  const key = normalizeWord(word);
  const base = dictionary[key];
  if (!base) return null;
  const variants = [parsePronunciation(base)];
  for (let i = 2; dictionary[`${key}(${i})`]; i++) variants.push(parsePronunciation(dictionary[`${key}(${i})`]));
  if (WEAK_H_WORDS.has(key)) variants.push(...variants.map((units) => units.slice(1)));
  return variants;
}

export function pronunciationIpa(units) {
  return units.map(unitIpa).join('');
}

function unitIpa({ phoneme, stress }) {
  if (phoneme === 'AH' && stress === 0) return 'ə';
  if (phoneme === 'ER' && stress === 0) return 'ɚ';
  return IPA[phoneme] ?? phoneme;
}

export const phonemeIpa = (phoneme, stress = null) => (phoneme ? unitIpa({ phoneme, stress }) : '');

// Chuyển một đoạn văn thành mục tiêu chấm điểm; trả về các từ không có trong từ điển.
export function textToTarget(text) {
  const tokens = tokenizeText(text);
  const unknown = [];
  const words = tokens.map(({ raw, key }) => {
    const variants = pronunciations(key);
    if (!variants) unknown.push(raw);
    return { word: raw, variants };
  });
  return { words, unknown };
}
