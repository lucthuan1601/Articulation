// Điểm vào duy nhất của module AI cho các phần khác của ứng dụng.
import { measureFluency } from './fluency.js';
import { createRecognizer } from './recognizer.js';
import { prepareTarget, scorePronunciation } from './scorer.js';
import { decodeWav, validateSpeech } from './wav.js';

export { createRecognizer };
export { AudioError } from './wav.js';
export { ModelBusyError, ModelUnavailableError } from './recognizer.js';

/**
 * Phân tích một đoạn ghi âm so với câu mục tiêu.
 * @param {{wav: Buffer, text: string, recognizer: {recognize: Function, engine: string}}} input
 */
export async function analyzeSpeech({ wav, text, recognizer }) {
  prepareTarget(text);
  const samples = decodeWav(wav);
  const { seconds, noisy } = validateSpeech(samples);
  const { phonemes, evidence } = await recognizer.recognize(samples);
  return {
    ...scorePronunciation(text, phonemes, evidence),
    fluency: measureFluency(samples, phonemes.length).score,
    noisy,
    audioMs: Math.round(seconds * 1000),
    engine: recognizer.engine,
  };
}
