// Khởi động dịch vụ AI. Mặc định chỉ nhận kết nối trong máy; máy ảo Android gọi qua 10.0.2.2.
// Điện thoại thật cần HOST=0.0.0.0, khi đó mọi máy cùng mạng đều gọi được vì API không có xác thực.
import { resolve } from 'node:path';
import { createRecognizer } from './ai/index.js';
import { createApp } from './app.js';

const host = process.env.HOST ?? '127.0.0.1';
const port = Number(process.env.PORT ?? 8787);

const recognizer = createRecognizer({ cacheDir: resolve(import.meta.dirname, '.models') });
recognizer.preload().catch((error) => console.error(`Không nạp được mô hình: ${error.message}`));

createApp({ recognizer }).listen(port, host, () => {
  console.log(`Dịch vụ AI đang chạy tại http://${host}:${port}`);
});
