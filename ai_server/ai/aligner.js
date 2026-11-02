// Căn chỉnh chuỗi âm nghe được với câu mục tiêu (Needleman-Wunsch mở rộng theo từ).
// Mỗi từ có thể có nhiều cách đọc đúng; quy hoạch động chọn tổ hợp cách đọc có chi phí nhỏ nhất.
import { deleteCost, INSERT_COST, substituteCost } from './similarity.js';

const OP = { SUB: 1, DEL: 2, INS: 3 };

function alignVariant(units, heard, startCosts) {
  const rows = units.length + 1;
  const cols = heard.length + 1;
  const cost = Array.from({ length: rows }, () => new Float64Array(cols));
  const ops = Array.from({ length: rows }, () => new Uint8Array(cols));

  for (let j = 0; j < cols; j++) cost[0][j] = startCosts[j];
  // Hàng 0 giữ nguyên startCosts: âm thừa trước từ đã được tính ở từ trước đó.
  for (let i = 1; i < rows; i++) {
    const { phoneme, stress } = units[i - 1];
    for (let j = 0; j < cols; j++) {
      let best = cost[i - 1][j] + deleteCost(phoneme, stress);
      let op = OP.DEL;
      if (j > 0) {
        const sub = cost[i - 1][j - 1] + substituteCost(phoneme, heard[j - 1], stress);
        if (sub <= best) { best = sub; op = OP.SUB; }
        const ins = cost[i][j - 1] + INSERT_COST;
        if (ins < best) { best = ins; op = OP.INS; }
      }
      cost[i][j] = best;
      ops[i][j] = op;
    }
  }
  return { cost, ops };
}

function backtrace(units, heard, ops, endColumn) {
  const pairs = [];
  const extras = [];
  let i = units.length;
  let j = endColumn;
  while (i > 0) {
    const op = ops[i][j];
    if (op === OP.SUB) {
      pairs.unshift({ ...units[i - 1], heard: heard[j - 1], heardIndex: j - 1 });
      i--; j--;
    } else if (op === OP.DEL) {
      pairs.unshift({ ...units[i - 1], heard: null, heardIndex: null });
      i--;
    } else {
      extras.unshift(heard[j - 1]);
      j--;
    }
  }
  return { pairs, extras, startColumn: j };
}

/**
 * @param {{word: string, variants: {phoneme: string, stress: number|null}[][]}[]} words
 * @param {string[]} heard
 */
export function alignWords(words, heard) {
  const cols = heard.length + 1;
  // Âm thừa đầu câu: phạt nhẹ để không ép chúng vào từ đầu tiên.
  let current = Float64Array.from({ length: cols }, (_, j) => j * INSERT_COST);
  const trace = [];

  for (const { variants } of words) {
    const next = new Float64Array(cols).fill(Infinity);
    const choice = new Int32Array(cols).fill(-1);
    const tables = variants.map((units) => alignVariant(units, heard, current));
    tables.forEach(({ cost }, v) => {
      const last = cost[cost.length - 1];
      for (let j = 0; j < cols; j++) {
        if (last[j] < next[j]) { next[j] = last[j]; choice[j] = v; }
      }
    });
    trace.push({ tables, choice });
    current = next;
  }

  // Âm thừa cuối câu.
  let end = 0;
  let bestTotal = Infinity;
  for (let j = 0; j < cols; j++) {
    const total = current[j] + (cols - 1 - j) * INSERT_COST;
    if (total < bestTotal) { bestTotal = total; end = j; }
  }

  const trailing = heard.slice(end);
  const aligned = new Array(words.length);
  for (let w = words.length - 1; w >= 0; w--) {
    const { tables, choice } = trace[w];
    const variant = choice[end];
    const units = words[w].variants[variant];
    const { pairs, extras, startColumn } = backtrace(units, heard, tables[variant].ops, end);
    aligned[w] = { word: words[w].word, variant: units, pairs, extras };
    end = startColumn;
  }
  const leading = heard.slice(0, end);
  return { words: aligned, leading, trailing, cost: bestTotal };
}
