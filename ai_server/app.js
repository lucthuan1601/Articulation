// API HTTP của dịch vụ AI: nhận WAV và câu mục tiêu, trả về kết quả chấm điểm.
import express from 'express';
import { analyzeSpeech, AudioError, ModelBusyError, ModelUnavailableError } from './ai/index.js';

// WAV 16 kHz mono 16-bit dài 30 giây khoảng 1 MB.
const MAX_UPLOAD = '2mb';
const MAX_TEXT_LENGTH = 1000;

function clientError(status, code, message) {
  return Object.assign(new Error(message), { status, code });
}

function toHttpError(error) {
  if (error.status && error.code) return error;
  if (error instanceof AudioError) {
    return clientError(error.code === 'BAD_AUDIO' ? 400 : 422, error.code, error.message);
  }
  if (error.code === 'UNKNOWN_WORDS' || error.code === 'EMPTY_TARGET') {
    return Object.assign(clientError(422, error.code, error.message), { words: error.words });
  }
  if (error instanceof ModelBusyError) {
    return clientError(503, 'MODEL_BUSY', 'Hệ thống đang bận, hãy thử lại sau ít phút');
  }
  if (error instanceof ModelUnavailableError) {
    return clientError(503, 'MODEL_UNAVAILABLE', 'Mô hình AI chưa sẵn sàng, hãy thử lại sau');
  }
  if (error.type === 'entity.too.large') {
    return clientError(413, 'TOO_LARGE', 'Tệp ghi âm quá lớn');
  }
  console.error(error);
  return clientError(500, 'INTERNAL', 'Máy chủ gặp lỗi khi phân tích');
}

export function createApp({ recognizer }) {
  const app = express();

  app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', model: recognizer.status() });
  });

  app.post(
    '/api/pronunciation/analyze',
    express.raw({ type: 'audio/wav', limit: MAX_UPLOAD }),
    async (req, res) => {
      const text = typeof req.query.text === 'string' ? req.query.text.trim() : '';
      if (!text || text.length > MAX_TEXT_LENGTH) {
        throw clientError(400, 'BAD_TEXT', 'Thiếu câu mục tiêu hoặc câu quá dài');
      }
      if (!Buffer.isBuffer(req.body)) {
        throw clientError(415, 'BAD_AUDIO', 'Dữ liệu gửi lên phải là audio/wav');
      }
      res.json(await analyzeSpeech({ wav: req.body, text, recognizer }));
    },
  );

  app.use((error, _req, res, _next) => {
    const { status, code, message, words } = toHttpError(error);
    res.status(status).json({ error: { code, message, words } });
  });

  return app;
}
