import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { alignWords } from '../ai/aligner.js';
import { analyzeSpeech, AudioError } from '../ai/index.js';
import { heardToken, pronunciations, textToTarget, tokensToPhonemes } from '../ai/phonemes.js';
import { greedyCtcDecode } from '../ai/recognizer.js';
import { scorePronunciation } from '../ai/scorer.js';
import { similarity } from '../ai/similarity.js';
import { decodeWav, measureSpeech, SAMPLE_RATE, validateSpeech } from '../ai/wav.js';

const phonemesOf = (text) => textToTarget(text).words.flatMap((w) => w.variants[0].map((u) => u.phoneme));

function replacePhoneme(list, from, to) {
  return list.flatMap((p) => (p === from ? (to ? [to] : []) : [p]));
}

function makeWav(samples, rate = SAMPLE_RATE) {
  const buffer = Buffer.alloc(44 + samples.length * 2);
  buffer.write('RIFF', 0, 'ascii');
  buffer.writeUInt32LE(36 + samples.length * 2, 4);
  buffer.write('WAVEfmt ', 8, 'ascii');
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(rate, 24);
  buffer.writeUInt32LE(rate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36, 'ascii');
  buffer.writeUInt32LE(samples.length * 2, 40);
  samples.forEach((s, i) => buffer.writeInt16LE(Math.round(s * 32767), 44 + i * 2));
  return buffer;
}

const tone = (seconds, amplitude = 0.3) => Array.from({ length: Math.floor(seconds * SAMPLE_RATE) },
  (_, i) => amplitude * Math.sin((2 * Math.PI * 220 * i) / SAMPLE_RATE));

describe('ánh xạ âm vị', () => {
  it('quy token espeak về ARPAbet', () => {
    assert.deepEqual(tokensToPhonemes(['θ', 'ɪ', 'ŋ', 'k']), ['TH', 'IH', 'NG', 'K']);
    assert.deepEqual(heardToken('ɑːɹ'), ['AA', 'R']);
    assert.deepEqual(heardToken('aɪɚ'), ['AY', 'ER']);
  });

  it('gộp nguyên âm đôi bị tách thành hai token', () => {
    assert.deepEqual(tokensToPhonemes(['b', 'ɔ', 'ɪ']), ['B', 'OY']);
    assert.deepEqual(tokensToPhonemes(['w', 'ɜː', 'ɹ', 'k']), ['W', 'ER', 'K']);
  });

  it('không gộp /ə ɹ/ khi /ɹ/ mở đầu âm tiết sau', () => {
    assert.deepEqual(tokensToPhonemes(['ə', 'ɹ', 'ɛ', 'd']), ['AH', 'R', 'EH', 'D']);
  });

  it('xử lý token có dấu phụ của ngôn ngữ khác', () => {
    assert.deepEqual(heardToken('tʰ'), ['T']);
    assert.deepEqual(heardToken('kː'), ['K']);
  });

  it('bỏ qua token không xác định thay vì làm hỏng chuỗi', () => {
    assert.deepEqual(heardToken('??'), []);
  });

  it('lấy đủ các cách đọc trong từ điển', () => {
    assert.ok(pronunciations('record').length >= 2);
    assert.equal(pronunciations('zzzqqq'), null);
  });

  it('chấp nhận dấu nháy cong và viết hoa', () => {
    assert.ok(pronunciations('Don’t'));
  });
});

describe('độ tương đồng', () => {
  it('coi âm vỗ là cách đọc đúng của t/d', () => {
    assert.equal(similarity('T', 'DX'), 1);
    assert.equal(similarity('D', 'DX'), 1);
  });

  it('chấp nhận nguyên âm rút gọn chỉ ở âm tiết không nhấn', () => {
    assert.equal(similarity('IY', 'AH', 0), 1);
    assert.ok(similarity('IY', 'AH', 1) < 1);
  });

  it('coi lỗi th -> t là sai chứ không phải gần đúng', () => {
    assert.ok(similarity('TH', 'T') < 0.5);
    assert.ok(similarity('DH', 'D') < 0.5);
  });

  it('điểm cặp s/z đối xứng và là gần đúng', () => {
    assert.equal(similarity('Z', 'S'), 0.5);
    assert.equal(similarity('S', 'Z'), 0.5);
  });
});

describe('căn chỉnh', () => {
  it('chọn cách đọc khớp nhất cho từng từ', () => {
    const words = [{ word: 'record', variants: pronunciations('record') }];
    const { words: [aligned] } = alignWords(words, ['R', 'EH', 'K', 'ER', 'D']);
    assert.equal(aligned.variant[1].phoneme, 'EH');
  });

  it('không làm sai lệch từ phía sau khi bị thiếu một từ', () => {
    const result = scorePronunciation('good morning my friend', phonemesOf('good my friend'));
    assert.equal(result.words[1].spoken, false);
    assert.equal(result.words[2].score, 100);
    assert.equal(result.words[3].score, 100);
  });

  it('âm thừa ở đầu và cuối câu không gán vào từ', () => {
    const heard = ['AH', 'M', ...phonemesOf('hello'), 'AH', 'M'];
    assert.equal(scorePronunciation('hello', heard).words[0].score, 100);
  });

  it('chuỗi nghe được rỗng không làm lỗi', () => {
    const result = scorePronunciation('hello world', []);
    assert.equal(result.overall, 0);
    assert.equal(result.completeness, 0);
    assert.equal(result.offTarget, true);
  });
});

describe('chấm điểm', () => {
  it('đọc đúng được 100 điểm', () => {
    const text = 'I think this is the right thing to do';
    const result = scorePronunciation(text, phonemesOf(text));
    assert.equal(result.overall, 100);
    assert.equal(result.accuracy, 100);
    assert.equal(result.issues.length, 0);
    assert.equal(result.verdict.level, 'excellent');
  });

  it('phát hiện th -> t và đưa bài tập phù hợp', () => {
    const text = 'think three things';
    const result = scorePronunciation(text, replacePhoneme(phonemesOf(text), 'TH', 'T'));
    assert.ok(result.overall < 90);
    assert.equal(result.issues[0].key, 'th-voiceless');
    assert.equal(result.issues[0].drill, 'drill-th-voiceless');
    assert.equal(result.issues[0].count, 3);
    assert.equal(result.words[0].phonemes[0].status, 'wrong');
  });

  it('phát hiện mất phụ âm cuối', () => {
    const result = scorePronunciation('good book', [...phonemesOf('good'), 'B', 'UH']);
    assert.equal(result.issues[0].key, 'final-consonant');
    assert.equal(result.words[1].phonemes.at(-1).status, 'missing');
  });

  it('phân biệt mất âm /s/ cuối với phụ âm cuối nói chung', () => {
    const result = scorePronunciation('books', ['B', 'UH', 'K']);
    assert.equal(result.issues[0].key, 'final-s');
  });

  it('kiểm tra đối lập bắt được /ð/ mà mô hình đã "sửa hộ"', () => {
    const heard = ['DH', 'IH', 'S'];
    const unsure = [{ DH: 0.55, D: 0.4 }, { IH: 0.99 }, { S: 0.99 }];
    const sure = [{ DH: 0.999, D: 0.001 }, { IH: 0.99 }, { S: 0.99 }];
    const flagged = scorePronunciation('this', heard, unsure);
    assert.equal(flagged.words[0].phonemes[0].heard, 'D');
    assert.equal(flagged.words[0].phonemes[0].uncertain, true);
    assert.equal(flagged.words[0].phonemes[1].uncertain, false);
    assert.equal(flagged.issues[0].key, 'th-voiced');
    assert.equal(scorePronunciation('this', heard, sure).overall, 100);
  });

  it('thiếu bằng chứng thì giữ nguyên kết quả nhận dạng', () => {
    assert.equal(scorePronunciation('this', ['DH', 'IH', 'S'], [null, null, null]).overall, 100);
  });

  it('chấp nhận rút gọn tự nhiên: bỏ /h/ ở từ chức năng và nguyên âm không nhấn', () => {
    assert.equal(scorePronunciation('him', ['IH', 'M']).overall, 100);
    assert.ok(scorePronunciation('family', ['F', 'AE', 'M', 'L', 'IY']).overall >= 90);
  });

  it('nhận ra người dùng đọc một câu khác hẳn', () => {
    const result = scorePronunciation('the quick brown fox', phonemesOf('my sister loves music'));
    assert.ok(result.overall < 40);
    assert.equal(result.offTarget, true);
  });

  it('âm chèn thêm làm giảm điểm nhẹ', () => {
    const clean = scorePronunciation('stop', ['S', 'T', 'AA', 'P']);
    const extra = scorePronunciation('stop', ['S', 'AH', 'T', 'AA', 'P']);
    assert.ok(extra.overall < clean.overall);
    assert.ok(extra.overall > 70);
  });

  it('từ chối từ không có trong từ điển và nêu rõ từ đó', () => {
    assert.throws(() => scorePronunciation('hello zzzqqq', []),
      (error) => error.code === 'UNKNOWN_WORDS' && error.words[0] === 'zzzqqq');
  });

  it('từ chối câu không có từ tiếng Anh', () => {
    assert.throws(() => scorePronunciation('123 !!!', []), (error) => error.code === 'EMPTY_TARGET');
  });

  it('điểm luôn trong khoảng 0..100', () => {
    for (const heard of [[], ['S'], Array(200).fill('K'), phonemesOf('hello hello hello hello')]) {
      const { overall } = scorePronunciation('hello', heard);
      assert.ok(overall >= 0 && overall <= 100);
    }
  });
});

describe('giải mã CTC', () => {
  it('gộp khung lặp, bỏ pad và giữ âm lặp có pad ở giữa', () => {
    const classes = 8;
    const frames = [5, 5, 0, 5, 7, 7];
    const logits = new Float32Array(frames.length * classes);
    frames.forEach((id, t) => { logits[t * classes + id] = 1; });
    const { tokens, evidence } = greedyCtcDecode(logits, frames.length, classes);
    assert.equal(tokens.length, 3);
    assert.equal(evidence.length, 3);
    assert.equal(tokens[0], tokens[1]);
  });
});

describe('xử lý âm thanh', () => {
  it('đọc WAV 16 kHz', () => {
    const samples = decodeWav(makeWav(tone(0.5)));
    assert.equal(samples.length, SAMPLE_RATE / 2);
  });

  it('chuyển mẫu từ 48 kHz về 16 kHz', () => {
    assert.equal(decodeWav(makeWav(tone(1), 48000)).length, Math.floor((SAMPLE_RATE * SAMPLE_RATE) / 48000));
  });

  it('từ chối dữ liệu không phải WAV', () => {
    assert.throws(() => decodeWav(Buffer.alloc(100)), (e) => e instanceof AudioError && e.code === 'BAD_AUDIO');
  });

  it('không treo với tệp WAV bị cắt cụt', () => {
    assert.throws(() => decodeWav(makeWav(tone(0.1)).subarray(0, 40)), AudioError);
  });

  it('từ chối đoạn im lặng', () => {
    assert.throws(() => validateSpeech(new Float32Array(SAMPLE_RATE)), (e) => e.code === 'NO_SPEECH');
  });

  it('từ chối đoạn quá ngắn và quá dài', () => {
    assert.throws(() => validateSpeech(Float32Array.from(tone(0.1))), (e) => e.code === 'TOO_SHORT');
    assert.throws(() => validateSpeech(new Float32Array(SAMPLE_RATE * 31)), (e) => e.code === 'TOO_LONG');
  });

  it('cảnh báo khi nền quá ồn', () => {
    let seed = 7;
    const noise = (amplitude) => {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return amplitude * (seed / 0x3fffffff - 1);
    };
    const speechWithGaps = (level) => Float32Array.from(
      [...tone(0.5), ...new Array(SAMPLE_RATE / 2).fill(0), ...tone(0.5)].map((s) => s + noise(level)),
    );
    assert.equal(validateSpeech(speechWithGaps(0.002)).noisy, false);
    assert.equal(validateSpeech(speechWithGaps(0.1)).noisy, true);
  });

  it('đo được thời lượng có tiếng', () => {
    const samples = Float32Array.from([...tone(0.5), ...new Array(SAMPLE_RATE / 2).fill(0)]);
    const { voicedSeconds } = measureSpeech(samples);
    assert.ok(voicedSeconds > 0.4 && voicedSeconds < 0.6);
  });
});

describe('analyzeSpeech', () => {
  const recognizer = (phonemes) => {
    const calls = [];
    return { engine: 'fake', calls, recognize: async (s) => { calls.push(s); return { tokens: [], phonemes }; } };
  };

  it('trả về kết quả kèm thời lượng và tên engine', async () => {
    const result = await analyzeSpeech({
      wav: makeWav(tone(1)), text: 'hello', recognizer: recognizer(phonemesOf('hello')),
    });
    assert.equal(result.overall, 100);
    assert.equal(result.audioMs, 1000);
    assert.equal(result.engine, 'fake');
  });

  it('không chạy mô hình khi câu mục tiêu không hợp lệ', async () => {
    const fake = recognizer([]);
    await assert.rejects(analyzeSpeech({ wav: makeWav(tone(1)), text: 'zzzqqq', recognizer: fake }),
      (error) => error.code === 'UNKNOWN_WORDS');
    assert.equal(fake.calls.length, 0);
  });

  it('không chạy mô hình khi âm thanh im lặng', async () => {
    const fake = recognizer([]);
    await assert.rejects(analyzeSpeech({ wav: makeWav(new Array(SAMPLE_RATE).fill(0)), text: 'hello', recognizer: fake }),
      (error) => error.code === 'NO_SPEECH');
    assert.equal(fake.calls.length, 0);
  });
});
