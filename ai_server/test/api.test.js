import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import { ModelBusyError, ModelUnavailableError } from '../ai/index.js';
import { measureFluency } from '../ai/fluency.js';
import { prepareTarget, scorePronunciation } from '../ai/scorer.js';
import { SAMPLE_RATE } from '../ai/wav.js';
import { createApp } from '../app.js';

function makeWav(samples) {
  const data = Buffer.alloc(samples.length * 2);
  samples.forEach((value, i) => data.writeInt16LE(Math.round(value * 32767), i * 2));
  const header = Buffer.alloc(44);
  header.write('RIFF', 0, 'ascii');
  header.writeUInt32LE(36 + data.length, 4);
  header.write('WAVEfmt ', 8, 'ascii');
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22);
  header.writeUInt32LE(SAMPLE_RATE, 24);
  header.writeUInt32LE(SAMPLE_RATE * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36, 'ascii');
  header.writeUInt32LE(data.length, 40);
  return Buffer.concat([header, data]);
}

const tone = (seconds) => Float32Array.from(
  { length: Math.floor(seconds * SAMPLE_RATE) },
  (_, i) => 0.3 * Math.sin((2 * Math.PI * 220 * i) / SAMPLE_RATE),
);

function joined(...parts) {
  const output = new Float32Array(parts.reduce((sum, part) => sum + part.length, 0));
  let offset = 0;
  for (const part of parts) {
    output.set(part, offset);
    offset += part.length;
  }
  return output;
}

const silence = (seconds) => new Float32Array(Math.floor(seconds * SAMPLE_RATE));

describe('API phân tích phát âm', () => {
  let server;
  let base;
  let behaviour = async () => ({ tokens: [], phonemes: ['HH', 'AH', 'L', 'OW'], evidence: null });
  const recognizer = {
    engine: 'fake',
    status: () => ({ state: 'ready', failure: null }),
    recognize: (samples) => behaviour(samples),
  };

  before(async () => {
    await new Promise((resolve) => { server = createApp({ recognizer }).listen(0, '127.0.0.1', resolve); });
    base = `http://127.0.0.1:${server.address().port}`;
  });
  after(() => server.close());

  const analyze = (text, body = makeWav(tone(1)), type = 'audio/wav') => fetch(
    `${base}/api/pronunciation/analyze?text=${encodeURIComponent(text)}`,
    { method: 'POST', headers: { 'Content-Type': type }, body },
  );

  it('báo trạng thái mô hình', async () => {
    const body = await (await fetch(`${base}/api/health`)).json();
    assert.deepEqual(body, { status: 'ok', model: { state: 'ready', failure: null } });
  });

  it('chấm điểm và trả về lưu loát cùng gợi ý', async () => {
    const response = await analyze('Hello');
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(body.overall, 100);
    assert.equal(typeof body.fluency, 'number');
    assert.equal(body.words[0].suggestion, null);
  });

  it('thiếu câu mục tiêu trả 400', async () => {
    const response = await analyze('   ');
    assert.equal(response.status, 400);
    assert.equal((await response.json()).error.code, 'BAD_TEXT');
  });

  it('sai định dạng gửi lên trả 415', async () => {
    const response = await analyze('Hello', 'abc', 'text/plain');
    assert.equal(response.status, 415);
  });

  it('WAV hỏng trả 400', async () => {
    const response = await analyze('Hello', Buffer.from('not a wav file'));
    assert.equal(response.status, 400);
    assert.equal((await response.json()).error.code, 'BAD_AUDIO');
  });

  it('im lặng trả 422 NO_SPEECH', async () => {
    const response = await analyze('Hello', makeWav(silence(1)));
    assert.equal(response.status, 422);
    assert.equal((await response.json()).error.code, 'NO_SPEECH');
  });

  it('từ ngoài từ điển trả 422 kèm danh sách từ', async () => {
    const { error } = await (await analyze('zzzqqq')).json();
    assert.equal(error.code, 'UNKNOWN_WORDS');
    assert.deepEqual(error.words, ['zzzqqq']);
  });

  it('tệp quá lớn trả 413', async () => {
    const response = await analyze('Hello', Buffer.alloc(3 * 1024 * 1024));
    assert.equal(response.status, 413);
  });

  it('mô hình bận hoặc lỗi trả 503', async () => {
    for (const [error, code] of [
      [new ModelBusyError('x'), 'MODEL_BUSY'],
      [new ModelUnavailableError('x'), 'MODEL_UNAVAILABLE'],
    ]) {
      behaviour = async () => { throw error; };
      const response = await analyze('Hello');
      assert.equal(response.status, 503);
      assert.equal((await response.json()).error.code, code);
    }
  });
});

describe('gợi ý theo từ', () => {
  it('từ sai có gợi ý, từ đúng thì không', () => {
    const { words } = scorePronunciation('think so', ['T', 'IH', 'NG', 'K', 'S', 'OW']);
    assert.match(words[0].suggestion, /lưỡi/);
    assert.equal(words[1].suggestion, null);
  });

  it('từ không đọc được báo bỏ sót', () => {
    const { words } = scorePronunciation('think so', ['S', 'OW']);
    assert.equal(words[0].spoken, false);
    assert.match(words[0].suggestion, /chưa đọc/);
  });
});

describe('điểm lưu loát', () => {
  it('nói đủ nhanh và liền mạch được 100', () => {
    assert.equal(measureFluency(tone(2), 20).score, 100);
  });

  it('nói chậm bị trừ điểm', () => {
    const { score, rate } = measureFluency(tone(4), 24);
    assert.equal(rate, 6);
    assert.ok(score < 100 && score > 40);
  });

  it('bài ngắn không bị trừ vì đọc chậm', () => {
    assert.equal(measureFluency(tone(1), 4).score, 100);
  });

  it('khoảng ngừng dài bị trừ điểm, im lặng hai đầu thì không', () => {
    const smooth = measureFluency(joined(silence(1), tone(1), silence(1)), 8);
    const broken = measureFluency(joined(tone(0.5), silence(0.6), tone(0.5)), 8);
    assert.equal(smooth.pauses, 0);
    assert.equal(smooth.score, 100);
    assert.equal(broken.pauses, 1);
    assert.equal(broken.score, 88);
  });

  it('không có âm nào thì 0 điểm', () => {
    assert.equal(measureFluency(tone(1), 0).score, 0);
  });
});

describe('dữ liệu bài học của app', () => {
  const source = readFileSync(new URL('../../lib/core/database/seed_data.dart', import.meta.url), 'utf8');
  const lessons = [...source.matchAll(/'content':\s*(?:'((?:[^'\\]|\\.)*)'|"([^"]*)")/g)]
    .map((match) => (match[1] ?? match[2]).replace(/\\'/g, "'"));

  it('mọi bài học đều chấm được', () => {
    assert.ok(lessons.length > 0);
    const failed = lessons.filter((text) => {
      try {
        prepareTarget(text);
        return false;
      } catch {
        return true;
      }
    });
    assert.deepEqual(failed, []);
  });

  it('không bài nào vượt giới hạn gửi của API', () => {
    assert.ok(Math.max(...lessons.map((text) => text.length)) <= 1000);
  });
});
