/// Thu âm giọng người dùng thành file WAV
abstract class SpeechRecorder {
  /// Bắt đầu thu âm. Ném `PermissionFailure` nếu chưa có quyền micro,
  /// `AudioFailure` nếu không thu được.
  Future<void> start();

  /// Dừng thu âm và trả về đường dẫn file WAV.
  Future<String> stop();

  /// Hủy lần thu âm đang diễn ra và xóa file.
  Future<void> cancel();

  /// Xóa file ghi âm không còn cần giữ.
  Future<void> discard(String path);

  /// Giải phóng tài nguyên.
  Future<void> dispose();
}
