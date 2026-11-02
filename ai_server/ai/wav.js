// Đọc WAV PCM và kiểm tra tín hiệu trước khi đưa vào mô hình.
export const SAMPLE_RATE = 16000;
export const MIN_SECONDS = 0.3;
export const MAX_SECONDS = 30;
export const FRAME_SECONDS = 0.02;
const NOISY_SNR_DB = 20;

export class AudioError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

export function decodeWav(buffer) {
  if (buffer.length < 44 || buffer.toString('ascii', 0, 4) !== 'RIFF' || buffer.toString('ascii', 8, 12) !== 'WAVE') {
    throw new AudioError('BAD_AUDIO', 'Tệp âm thanh không phải WAV hợp lệ');
  }
  let offset = 12;
  let format = null;
  let data = null;
  while (offset + 8 <= buffer.length) {
    const id = buffer.toString('ascii', offset, offset + 4);
    const size = buffer.readUInt32LE(offset + 4);
    const start = offset + 8;
    if (id === 'fmt ' && start + 16 <= buffer.length) {
      format = {
        code: buffer.readUInt16LE(start),
        channels: buffer.readUInt16LE(start + 2),
        rate: buffer.readUInt32LE(start + 4),
        bits: buffer.readUInt16LE(start + 14),
      };
    } else if (id === 'data') {
      data = buffer.subarray(start, Math.min(start + size, buffer.length));
    }
    offset = start + size + (size % 2);
  }
  if (!format || !data) throw new AudioError('BAD_AUDIO', 'Tệp WAV thiếu dữ liệu');
  const isPcm16 = format.code === 1 && format.bits === 16;
  const isFloat32 = format.code === 3 && format.bits === 32;
  if ((!isPcm16 && !isFloat32) || format.channels < 1 || format.rate < 8000) {
    throw new AudioError('BAD_AUDIO', 'Chỉ hỗ trợ WAV PCM 16-bit hoặc float 32-bit');
  }

  const bytes = isPcm16 ? 2 : 4;
  const frames = Math.floor(data.length / (bytes * format.channels));
  const mono = new Float32Array(frames);
  for (let i = 0; i < frames; i++) {
    let sum = 0;
    for (let c = 0; c < format.channels; c++) {
      const at = (i * format.channels + c) * bytes;
      sum += isPcm16 ? data.readInt16LE(at) / 32768 : data.readFloatLE(at);
    }
    mono[i] = sum / format.channels;
  }
  return format.rate === SAMPLE_RATE ? mono : resample(mono, format.rate, SAMPLE_RATE);
}

function resample(input, from, to) {
  const length = Math.floor((input.length * to) / from);
  const output = new Float32Array(length);
  const step = from / to;
  for (let i = 0; i < length; i++) {
    const position = i * step;
    const left = Math.floor(position);
    const right = Math.min(left + 1, input.length - 1);
    output[i] = input[left] + (input[right] - input[left]) * (position - left);
  }
  return output;
}

// Năng lượng của từng khung 20 ms.
export function frameEnergies(samples) {
  const frame = Math.floor(SAMPLE_RATE * FRAME_SECONDS);
  const energies = [];
  for (let i = 0; i + frame <= samples.length; i += frame) {
    let sum = 0;
    for (let j = i; j < i + frame; j++) sum += samples[j] * samples[j];
    energies.push(Math.sqrt(sum / frame));
  }
  return energies;
}

export function voicedThreshold(energies) {
  const peak = energies.reduce((max, e) => Math.max(max, e), 0);
  return Math.max(peak * 0.1, 0.002);
}

// Đếm thời lượng có tiếng nói theo năng lượng từng khung.
export function measureSpeech(samples) {
  const energies = frameEnergies(samples);
  if (energies.length === 0) return { peak: 0, voicedSeconds: 0, snrDb: 0 };
  const peak = energies.reduce((max, e) => Math.max(max, e), 0);
  const threshold = voicedThreshold(energies);
  const voiced = energies.filter((e) => e >= threshold).length;
  // Ước lượng tỉ số tín hiệu/nhiễu: khung ồn nhất so với các khung yên lặng nhất.
  const sorted = [...energies].sort((a, b) => a - b);
  const floor = sorted[Math.floor(sorted.length * 0.1)];
  const loud = sorted[Math.floor(sorted.length * 0.95)];
  const snrDb = 20 * Math.log10(loud / Math.max(floor, 1e-5));
  return { peak, voicedSeconds: voiced * FRAME_SECONDS, snrDb };
}

export function validateSpeech(samples) {
  const seconds = samples.length / SAMPLE_RATE;
  if (seconds < MIN_SECONDS) throw new AudioError('TOO_SHORT', 'Đoạn ghi âm quá ngắn');
  if (seconds > MAX_SECONDS) throw new AudioError('TOO_LONG', `Đoạn ghi âm dài quá ${MAX_SECONDS} giây`);
  const { peak, voicedSeconds, snrDb } = measureSpeech(samples);
  if (peak < 0.005 || voicedSeconds < 0.15) {
    throw new AudioError('NO_SPEECH', 'Không nghe thấy giọng nói. Hãy kiểm tra micro và thử lại');
  }
  return { seconds, snrDb, noisy: snrDb < NOISY_SNR_DB };
}
