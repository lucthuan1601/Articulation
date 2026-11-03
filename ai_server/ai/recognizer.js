// Nhận dạng âm vị bằng wav2vec2 (ONNX) chạy cục bộ. Khác với ASR thường, mô hình trả về âm thực
// sự nghe được thay vì "đoán" thành từ đúng, nên phát hiện được lỗi như think -> tink.
import { readFileSync } from 'node:fs';
import { heardToken, tokensToHeard } from './phonemes.js';

const MODEL_ID = 'onnx-community/wav2vec2-lv-60-espeak-cv-ft-ONNX';
const MODEL_REVISION = 'c69750f5043e5e1f8a71ab95dd3b98338c280c92';
const MODEL_DTYPE = 'int8';
const MAX_QUEUE = 8;

const vocab = JSON.parse(readFileSync(new URL('./vocab.json', import.meta.url), 'utf8'));
const idToToken = Object.fromEntries(Object.entries(vocab).map(([token, id]) => [id, token]));
const SPECIAL_TOKENS = new Set(['<pad>', '<s>', '</s>', '<unk>']);

export class ModelBusyError extends Error {}
export class ModelUnavailableError extends Error {}

// Token -> âm ARPAbet đơn lẻ, dùng để cộng xác suất theo âm khi kiểm tra đối lập.
const classOfId = Object.fromEntries(Object.entries(idToToken).flatMap(([id, token]) => {
  if (SPECIAL_TOKENS.has(token)) return [];
  const phonemes = heardToken(token);
  return phonemes.length === 1 ? [[id, phonemes[0]]] : [];
}));

function frameBest(logits, t, classes) {
  let best = 0;
  let bestValue = -Infinity;
  for (let c = 0; c < classes; c++) {
    const value = logits[t * classes + c];
    if (value > bestValue) { bestValue = value; best = c; }
  }
  return best;
}

// Xác suất trung bình của từng âm trên các khung [start, end).
function spanEvidence(logits, start, end, classes) {
  const totals = {};
  for (let t = start; t < end; t++) {
    let max = -Infinity;
    for (let c = 0; c < classes; c++) max = Math.max(max, logits[t * classes + c]);
    let sum = 0;
    for (let c = 0; c < classes; c++) sum += Math.exp(logits[t * classes + c] - max);
    for (let c = 0; c < classes; c++) {
      const phoneme = classOfId[c];
      if (phoneme) totals[phoneme] = (totals[phoneme] ?? 0) + Math.exp(logits[t * classes + c] - max) / sum;
    }
  }
  const frames = end - start;
  return Object.fromEntries(Object.entries(totals)
    .map(([phoneme, value]) => [phoneme, Number((value / frames).toPrecision(4))])
    .filter(([, value]) => value >= 1e-5));
}

export function greedyCtcDecode(logits, frames, classes) {
  const tokens = [];
  const evidence = [];
  let t = 0;
  while (t < frames) {
    const id = frameBest(logits, t, classes);
    let end = t + 1;
    while (end < frames && frameBest(logits, end, classes) === id) end += 1;
    const token = idToToken[id];
    if (token && !SPECIAL_TOKENS.has(token)) {
      tokens.push(token);
      evidence.push(spanEvidence(logits, t, end, classes));
    }
    t = end;
  }
  return { tokens, evidence };
}

// Gộp bằng chứng khi nhiều token tạo thành một âm (ví dụ ɔ + ɪ -> OY).
export function heardWithEvidence(tokens, tokenEvidence) {
  const heard = tokensToHeard(tokens);
  return {
    phonemes: heard.map((item) => item.phoneme),
    evidence: heard.map((item) => (item.sources.length === 1 ? tokenEvidence[item.sources[0]] : null)),
  };
}

export function createRecognizer({ cacheDir }) {
  let state = 'idle';
  let failure = null;
  let loading = null;
  let queue = Promise.resolve();
  let waiting = 0;

  async function load() {
    state = 'loading';
    try {
      const { AutoModelForCTC, AutoProcessor, env } = await import('@huggingface/transformers');
      env.cacheDir = cacheDir;
      const options = { revision: MODEL_REVISION };
      const processor = await AutoProcessor.from_pretrained(MODEL_ID, options);
      const model = await AutoModelForCTC.from_pretrained(MODEL_ID, { ...options, dtype: MODEL_DTYPE });
      state = 'ready';
      failure = null;
      return { processor, model };
    } catch (error) {
      state = 'failed';
      failure = error.message;
      loading = null;
      throw error;
    }
  }

  function ensureLoaded() {
    loading ??= load();
    return loading;
  }

  async function infer(samples) {
    const { processor, model } = await ensureLoaded();
    const inputs = await processor(samples);
    const { logits } = await model(inputs);
    const [, frames, classes] = logits.dims;
    const { tokens, evidence } = greedyCtcDecode(logits.data, frames, classes);
    return { tokens, tokenEvidence: evidence, ...heardWithEvidence(tokens, evidence) };
  }

  return {
    engine: MODEL_ID,
    status: () => ({ state, failure }),
    preload: () => ensureLoaded(),
    // Suy luận chiếm nhiều CPU nên xếp hàng tuần tự; hàng đợi đầy thì từ chối thay vì treo máy.
    recognize(samples) {
      if (waiting >= MAX_QUEUE) return Promise.reject(new ModelBusyError('Hệ thống đang bận'));
      waiting += 1;
      const run = queue.then(() => infer(samples)).catch((error) => {
        if (error instanceof ModelBusyError) throw error;
        throw new ModelUnavailableError(error.message);
      }).finally(() => { waiting -= 1; });
      queue = run.catch(() => {});
      return run;
    },
  };
}
