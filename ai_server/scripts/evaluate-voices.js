// Đánh giá module AI trên nhiều giọng nói. Dùng: node scripts/evaluate-voices.js [l2] [native] [synthetic] [fluency]
//   l2        giọng người học thật (L2-ARCTIC), so với âm do người gán nhãn
//   native    giọng bản ngữ thật (LibriSpeech), đo tỉ lệ báo sai
//   synthetic giọng Windows SAPI: cấy lỗi có chủ đích, đổi tốc độ, thêm nhiễu
// Kết quả nhận dạng được lưu đệm trong .eval-data/cache để chỉnh ngưỡng không phải chạy lại mô hình.
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { asyncBufferFromFile, parquetReadObjects } from 'hyparquet';
import { FLACDecoder } from '@wasm-audio-decoders/flac';
import { alignWords } from '../ai/aligner.js';
import { measureFluency } from '../ai/fluency.js';
import { createRecognizer } from '../ai/index.js';
import { textToTarget } from '../ai/phonemes.js';
import { heardWithEvidence } from '../ai/recognizer.js';
import { resolveHeard, scorePronunciation } from '../ai/scorer.js';
import { phonemeScore } from '../ai/similarity.js';
import { decodeWav, measureSpeech, SAMPLE_RATE } from '../ai/wav.js';

const ROOT = resolve(import.meta.dirname, '..');
const DATA = resolve(ROOT, '.eval-data');
const CACHE = resolve(DATA, 'cache');
const REPORT = resolve(ROOT, 'docs', 'ai-evaluation.json');
mkdirSync(CACHE, { recursive: true });
mkdirSync(resolve(ROOT, 'docs'), { recursive: true });

const recognizer = createRecognizer({ cacheDir: resolve(ROOT, '.models') });

async function recognizeCached(key, getSamples) {
  const path = resolve(CACHE, `${createHash('sha1').update(key).digest('hex')}.json`);
  if (existsSync(path)) {
    const { tokens, tokenEvidence } = JSON.parse(readFileSync(path, 'utf8'));
    return heardWithEvidence(tokens, tokenEvidence);
  }
  const { tokens, tokenEvidence } = await recognizer.recognize(await getSamples());
  const recognized = heardWithEvidence(tokens, tokenEvidence);
  writeFileSync(path, JSON.stringify({ tokens, tokenEvidence }));
  return recognized;
}

const mean = (list) => (list.length ? list.reduce((a, b) => a + b, 0) / list.length : 0);
const round = (value, digits = 1) => Math.round(value * 10 ** digits) / 10 ** digits;

function pearson(xs, ys) {
  const mx = mean(xs);
  const my = mean(ys);
  let num = 0; let dx = 0; let dy = 0;
  xs.forEach((x, i) => {
    num += (x - mx) * (ys[i] - my);
    dx += (x - mx) ** 2;
    dy += (ys[i] - my) ** 2;
  });
  return num / Math.sqrt(dx * dy);
}

const isError = (phoneme, heard, stress) => phonemeScore(phoneme, heard, stress) < 0.5;

function emptyCounts() {
  return { tp: 0, fp: 0, fn: 0, tn: 0, goldScores: [], predScores: [], clips: 0 };
}

function summarize(c) {
  const precision = c.tp / (c.tp + c.fp || 1);
  const recall = c.tp / (c.tp + c.fn || 1);
  return {
    clips: c.clips,
    phonemes: c.tp + c.fp + c.fn + c.tn,
    humanErrorRate: round(((c.tp + c.fn) / (c.tp + c.fp + c.fn + c.tn || 1)) * 100),
    precision: round(precision * 100),
    recall: round(recall * 100),
    f1: round((2 * precision * recall / (precision + recall || 1)) * 100),
    falseAlarmRate: round((c.fp / (c.fp + c.tn || 1)) * 100),
    scoreCorrelation: round(pearson(c.goldScores, c.predScores), 2),
    meanGoldScore: round(mean(c.goldScores)),
    meanPredScore: round(mean(c.predScores)),
  };
}

const MARGIN_GRID = [0, 0.69, 1.1, 1.61, 2.3, 3.4, 4.61, 5.5, 6.9, 9.2];
const GOLD_DROP = new Set(['', ' ', 'SIL', 'SP', 'SPN', 'DA', 'ERR']);

function cleanGold(phones) {
  return phones.map((p) => p.trim().toUpperCase().replace(/[0-9*]/g, ''))
    .filter((p) => !GOLD_DROP.has(p))
    .map((p) => (p === 'AX' ? 'AH' : p === 'DX' ? 'DX' : p));
}

function compareClip(text, gold, { phonemes: heard, evidence }, margin, counts) {
  const { words } = textToTarget(text);
  const goldAligned = alignWords(words, gold).words;
  // Chấm cả hai phía trên cùng một cách đọc để so sánh được từng âm vị.
  const pinned = goldAligned.map((w) => ({ word: w.word, variants: [w.variant] }));
  const predAligned = alignWords(pinned, heard).words;
  goldAligned.forEach((goldWord, w) => {
    goldWord.pairs.forEach((pair, i) => {
      const predPair = predAligned[w].pairs[i];
      const goldBad = isError(pair.phoneme, pair.heard, pair.stress);
      const predBad = isError(predPair.phoneme, resolveHeard(predPair, evidence, margin), predPair.stress);
      if (goldBad && predBad) counts.tp += 1;
      else if (predBad) counts.fp += 1;
      else if (goldBad) counts.fn += 1;
      else counts.tn += 1;
    });
  });
  counts.goldScores.push(scorePronunciation(text, gold).overall);
  counts.predScores.push(scorePronunciation(text, heard, evidence, margin).overall);
  counts.clips += 1;
}

async function evaluateL2() {
  const file = await asyncBufferFromFile(resolve(DATA, 'l2arctic', 'train.parquet'));
  const rows = await parquetReadObjects({ file });
  const clips = [];
  let skipped = 0;
  for (const [index, row] of rows.entries()) {
    if (textToTarget(row.text).unknown.length > 0) { skipped += 1; continue; }
    const recognized = await recognizeCached(`l2:${row.filename}`, () => Float32Array.from(row.waveform));
    clips.push({ speaker: row.speaker, language: row.native_language, text: row.text, gold: cleanGold([...row.phones]), recognized });
    if ((index + 1) % 25 === 0) console.error(`l2: ${index + 1}/${rows.length}`);
  }
  const tally = (selected, margin) => {
    const counts = emptyCounts();
    for (const clip of selected) compareClip(clip.text, clip.gold, clip.recognized, margin, counts);
    return counts;
  };
  const f1Of = (counts) => summarize(counts).f1;

  // Chọn ngưỡng trên hai người nói, đo trên người thứ ba, để số liệu không bị học thuộc.
  const speakers = [...new Set(clips.map((clip) => clip.speaker))];
  const pooled = emptyCounts();
  const perSpeaker = {};
  for (const speaker of speakers) {
    const train = clips.filter((clip) => clip.speaker !== speaker);
    const test = clips.filter((clip) => clip.speaker === speaker);
    const margin = MARGIN_GRID.reduce((best, m) => (f1Of(tally(train, m)) > f1Of(tally(train, best)) ? m : best), Infinity);
    const counts = tally(test, margin);
    perSpeaker[speaker] = { language: test[0].language, chosenMargin: margin, ...summarize(counts) };
    for (const key of ['tp', 'fp', 'fn', 'tn', 'clips']) pooled[key] += counts[key];
    pooled.goldScores.push(...counts.goldScores);
    pooled.predScores.push(...counts.predScores);
  }
  const sweep = Object.fromEntries(MARGIN_GRID.map((m) => [round(m, 2), summarize(tally(clips, m))]));
  return {
    skipped,
    withoutContrast: summarize(tally(clips, 0)),
    leaveOneSpeakerOut: summarize(pooled),
    perSpeaker,
    sweep,
  };
}

async function fetchNativeRows() {
  const path = resolve(DATA, 'librispeech.json');
  if (existsSync(path)) return JSON.parse(readFileSync(path, 'utf8'));
  const url = 'https://datasets-server.huggingface.co/rows?dataset=hf-internal-testing/librispeech_asr_dummy&config=clean&split=validation';
  const rows = [];
  for (let offset = 0; offset < 73; offset += 100) {
    const body = await (await fetch(`${url}&offset=${offset}&length=100`)).json();
    rows.push(...body.rows.map(({ row }) => ({ id: row.id, text: row.text, speaker: row.speaker_id, src: row.audio[0].src })));
  }
  writeFileSync(path, JSON.stringify(rows));
  return rows;
}

async function decodeFlac(url) {
  const bytes = new Uint8Array(await (await fetch(url)).arrayBuffer());
  const decoder = new FLACDecoder();
  await decoder.ready;
  const { channelData } = await decoder.decodeFile(bytes);
  decoder.free();
  return channelData[0];
}

async function evaluateNative() {
  const rows = await fetchNativeRows();
  const bySpeaker = new Map();
  let skipped = 0;
  for (const row of rows) {
    const { unknown } = textToTarget(row.text);
    if (unknown.length > 0) { skipped += 1; continue; }
    const { phonemes, evidence } = await recognizeCached(`native:${row.id}`, () => decodeFlac(row.src));
    const { overall, accuracy, words } = scorePronunciation(row.text, phonemes, evidence);
    const entry = bySpeaker.get(row.speaker) ?? { scores: [], accuracy: [], poorWords: 0, words: 0 };
    entry.scores.push(overall);
    entry.accuracy.push(accuracy);
    entry.poorWords += words.filter((w) => w.status === 'poor').length;
    entry.words += words.length;
    bySpeaker.set(row.speaker, entry);
  }
  const all = [...bySpeaker.values()];
  const totalWords = all.reduce((sum, e) => sum + e.words, 0);
  const poor = all.reduce((sum, e) => sum + e.poorWords, 0);
  const scores = all.flatMap((e) => e.scores);
  return {
    skipped,
    speakers: bySpeaker.size,
    clips: scores.length,
    meanScore: round(mean(scores)),
    minScore: Math.min(...scores),
    poorWordRate: round((poor / totalWords) * 100),
  };
}

function synthesize(voice, ssmlOrText, rate, out) {
  const script = `
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.SelectVoice($env:EVAL_VOICE); $s.Rate = [int]$env:EVAL_RATE
$f = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(16000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$s.SetOutputToWaveFile($env:EVAL_OUT, $f); $s.Speak($env:EVAL_TEXT); $s.Dispose()`;
  execFileSync('powershell', ['-NoProfile', '-Command', script], {
    env: { ...process.env, EVAL_VOICE: voice, EVAL_TEXT: ssmlOrText, EVAL_RATE: String(rate), EVAL_OUT: out },
    stdio: 'ignore',
  });
}

function addNoise(samples, snrDb) {
  const power = mean(Array.from(samples, (s) => s * s));
  const amplitude = Math.sqrt(power / 10 ** (snrDb / 10));
  let seed = 12345;
  const random = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
  return samples.map((s) => s + amplitude * Math.sqrt(-2 * Math.log(random() || 1e-9)) * Math.cos(2 * Math.PI * random()));
}

const VOICES = ['Microsoft David Desktop', 'Microsoft Zira Desktop'];
const CORRECT_SENTENCES = [
  'I think this is the right thing to do.', 'She drinks a cup of coffee before work.',
  'What time does the next train leave?', 'The street is very strong and straight.',
  'My friends work in big cities.', 'Thank you very much for your help.',
  'We need to discuss the budget before the meeting ends.', 'The children choose a cheap chair.',
];
// Đích, câu thực sự đọc (cố tình đọc sai) và lỗi mong đợi.
const INJECTED = [
  { target: 'I think about three things.', spoken: 'I tink about tree tings.', issue: 'th-voiceless', words: ['think', 'three', 'things'] },
  { target: 'This is my mother.', spoken: 'Dis is my mudder.', issue: 'th-voiced', words: ['This', 'mother'] },
  { target: 'The red light is on the right.', spoken: 'The led right is on the light.', issue: 'r-sound', words: ['red', 'right'] },
  { target: 'The sheep is on the ship.', spoken: 'The ship is on the sheep.', issue: 'long-short-i', words: ['sheep', 'ship'] },
  { target: 'He has a very good van.', spoken: 'He has a berry good ban.', issue: 'v-f-sound', words: ['very', 'van'] },
  { target: 'She sells fish.', spoken: 'See sells fiss.', issue: 'sh-sound', words: ['She', 'fish'] },
  { target: 'The man sat on the bed.', spoken: 'The men set on the bad.', issue: 'ae-eh', words: ['man', 'sat', 'bed'] },
  { target: 'Take the night bus.', spoken: 'Tay the nye buh.', issue: 'final-consonant', words: ['Take', 'night', 'bus'] },
  { target: 'She likes dogs and cats.', spoken: 'She like dog and cat.', issue: 'final-s', words: ['likes', 'dogs', 'cats'] },
];

function synthSamples(voice, text, rate, snr) {
  const out = resolve(DATA, 'synth.wav');
  synthesize(voice, text, rate, out);
  const samples = decodeWav(readFileSync(out));
  return snr === null ? samples : addNoise(samples, snr);
}

async function synthTokens(key, voice, text, rate, snr = null) {
  return recognizeCached(`synthetic:${key}`, () => {
    return synthSamples(voice, text, rate, snr);
  });
}

async function evaluateSynthetic() {
  const conditions = [
    { name: 'Tốc độ thường', rate: 0 }, { name: 'Đọc chậm', rate: -3 }, { name: 'Đọc nhanh', rate: 3 },
    { name: 'Nhiễu 20 dB', rate: 0, snr: 20 }, { name: 'Nhiễu 10 dB', rate: 0, snr: 10 }, { name: 'Nhiễu 5 dB', rate: 0, snr: 5 },
  ];
  const correct = {};
  for (const { name, rate, snr = null } of conditions) {
    const scores = [];
    for (const voice of VOICES) {
      for (const sentence of CORRECT_SENTENCES) {
        const { phonemes, evidence } = await synthTokens(`${voice}|${rate}|${snr}|${sentence}`, voice, sentence, rate, snr);
        scores.push(scorePronunciation(sentence, phonemes, evidence).overall);
      }
    }
    // Phát hiện ồn đo trên âm thanh thật của từng điều kiện, không qua cache nhận dạng.
    const snrs = VOICES.flatMap((voice) => CORRECT_SENTENCES.map((sentence) => measureSpeech(synthSamples(voice, sentence, rate, snr)).snrDb));
    correct[name] = {
      clips: scores.length, meanScore: round(mean(scores)), minScore: Math.min(...scores),
      meanSnrEstimate: round(mean(snrs)), flaggedNoisy: snrs.filter((value) => value < 20).length,
    };
  }

  const cases = [];
  for (const voice of VOICES) {
    for (const item of INJECTED) {
      const ok = await synthTokens(`${voice}|ok|${item.target}`, voice, item.target, 0);
      const wrong = await synthTokens(`${voice}|bad|${item.spoken}`, voice, item.spoken, 0);
      const good = scorePronunciation(item.target, ok.phonemes, ok.evidence);
      const bad = scorePronunciation(item.target, wrong.phonemes, wrong.evidence);
      const flagged = item.words.filter((word) => bad.words.find((w) => w.word === word)?.status !== 'good');
      cases.push({
        voice: voice.split(' ')[1],
        issue: item.issue,
        correctScore: good.overall,
        wrongScore: bad.overall,
        wordsFlagged: flagged.length,
        wordsInjected: item.words.length,
        issueNamed: bad.issues.some((issue) => issue.key === item.issue),
      });
    }
  }
  const injected = cases.reduce((sum, c) => sum + c.wordsInjected, 0);
  const flagged = cases.reduce((sum, c) => sum + c.wordsFlagged, 0);
  return {
    correct,
    injected: {
      clips: cases.length,
      wordDetectionRate: round((flagged / injected) * 100),
      issueNamedRate: round((cases.filter((c) => c.issueNamed).length / cases.length) * 100),
      meanCorrectScore: round(mean(cases.map((c) => c.correctScore))),
      meanWrongScore: round(mean(cases.map((c) => c.wrongScore))),
      cases,
    },
  };
}

function quantiles(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const at = (q) => round(sorted[Math.floor((sorted.length - 1) * q)]);
  return { min: at(0), p10: at(0.1), median: at(0.5), p90: at(0.9), max: at(1) };
}

// Chưa có nhãn lưu loát của người: chỉ kiểm tra phân bố và độ nhạy với tốc độ, khoảng ngừng.
async function evaluateFluency() {
  const file = await asyncBufferFromFile(resolve(DATA, 'l2arctic', 'train.parquet'));
  const rows = await parquetReadObjects({ file });
  const realSpeech = [];
  const withPauses = [];
  for (const row of rows) {
    if (textToTarget(row.text).unknown.length > 0) continue;
    const samples = Float32Array.from(row.waveform);
    const { phonemes } = await recognizeCached(`l2:${row.filename}`, () => samples);
    realSpeech.push(measureFluency(samples, phonemes.length));
    // Chèn hai khoảng lặng 0,8 giây để xem điểm có giảm đúng như một người đọc ngắt quãng không.
    const third = Math.floor(samples.length / 3);
    const gap = new Float32Array(Math.floor(SAMPLE_RATE * 0.8));
    const broken = new Float32Array(samples.length + 2 * gap.length);
    broken.set(samples.subarray(0, third), 0);
    broken.set(samples.subarray(third, 2 * third), third + gap.length);
    broken.set(samples.subarray(2 * third), 2 * third + 2 * gap.length);
    withPauses.push(measureFluency(broken, phonemes.length));
  }
  const bySpeed = {};
  for (const { name, rate } of [{ name: 'Đọc chậm', rate: -3 }, { name: 'Tốc độ thường', rate: 0 }, { name: 'Đọc nhanh', rate: 3 }]) {
    const measured = [];
    for (const voice of VOICES) {
      for (const sentence of CORRECT_SENTENCES) {
        const { phonemes } = await synthTokens(`${voice}|${rate}|null|${sentence}`, voice, sentence, rate);
        measured.push(measureFluency(synthSamples(voice, sentence, rate, null), phonemes.length));
      }
    }
    bySpeed[name] = { rate: quantiles(measured.map((m) => m.rate)), score: quantiles(measured.map((m) => m.score)) };
  }
  return {
    l2: {
      clips: realSpeech.length,
      rate: quantiles(realSpeech.map((m) => m.rate)),
      pauses: quantiles(realSpeech.map((m) => m.pauses)),
      score: quantiles(realSpeech.map((m) => m.score)),
    },
    l2WithInsertedPauses: { score: quantiles(withPauses.map((m) => m.score)) },
    synthetic: bySpeed,
  };
}

const requested = process.argv.slice(2);
const wants = (name) => requested.length === 0 || requested.includes(name);
const report = existsSync(REPORT) ? JSON.parse(readFileSync(REPORT, 'utf8')) : {};
if (wants('l2')) report.l2 = await evaluateL2();
if (wants('native')) report.native = await evaluateNative();
if (wants('synthetic')) report.synthetic = await evaluateSynthetic();
if (wants('fluency')) report.fluency = await evaluateFluency();
report.sampleRate = SAMPLE_RATE;
writeFileSync(REPORT, `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
