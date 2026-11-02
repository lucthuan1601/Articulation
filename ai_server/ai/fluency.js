// Điểm lưu loát: tốc độ nói và số khoảng ngừng dài bên trong câu.
// Không tham gia vào điểm `overall`, vì các số liệu đánh giá chỉ đo phát âm.
import { FRAME_SECONDS, frameEnergies, voicedThreshold } from './wav.js';

const PAUSE_SECONDS = 0.35;
const PHONEMES_PER_ALLOWED_PAUSE = 20;
const PAUSE_PENALTY = 12;
// Âm/giây. L2-ARCTIC: phân vị 10 là 9, trung vị 11,1. Giọng tổng hợp đọc chậm: trung vị 9,4.
const FULL_SCORE_RATE = 9;
const LOW_SCORE_RATE = 4;
const LOW_SCORE = 40;
// Bài chỉ có một hai từ thường được kéo dài âm khi đọc riêng, nên tốc độ không có ý nghĩa.
const MIN_PHONEMES_FOR_RATE = 10;

export function measureFluency(samples, phonemeCount) {
  const energies = frameEnergies(samples);
  const threshold = voicedThreshold(energies);
  const first = energies.findIndex((e) => e >= threshold);
  if (first < 0 || phonemeCount === 0) return { score: 0, rate: 0, pauses: 0 };
  const last = energies.findLastIndex((e) => e >= threshold);

  let pauses = 0;
  let pausedFrames = 0;
  let silent = 0;
  for (let i = first; i <= last; i++) {
    if (energies[i] >= threshold) {
      if (silent * FRAME_SECONDS >= PAUSE_SECONDS) {
        pauses += 1;
        pausedFrames += silent;
      }
      silent = 0;
    } else {
      silent += 1;
    }
  }

  const speakingSeconds = Math.max((last - first + 1 - pausedFrames) * FRAME_SECONDS, FRAME_SECONDS);
  const rate = phonemeCount / speakingSeconds;
  const slope = (100 - LOW_SCORE) / (FULL_SCORE_RATE - LOW_SCORE_RATE);
  const rateScore = phonemeCount < MIN_PHONEMES_FOR_RATE
    ? 100
    : Math.min(100, LOW_SCORE + (rate - LOW_SCORE_RATE) * slope);
  const extraPauses = Math.max(0, pauses - Math.floor(phonemeCount / PHONEMES_PER_ALLOWED_PAUSE));
  const score = Math.round(Math.max(0, rateScore - extraPauses * PAUSE_PENALTY));
  return { score, rate: Math.round(rate * 10) / 10, pauses };
}
