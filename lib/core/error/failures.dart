/// Lớp cơ sở cho các lỗi trong ứng dụng Articulation
/// Sử dụng pattern Failure để xử lý lỗi theo kiểu functional programming
abstract class Failure {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Lỗi liên quan đến cơ sở dữ liệu (SQLite/Floor)
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

/// Lỗi liên quan đến mạng (API calls)
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Lỗi liên quan đến xử lý giọng nói / ghi âm
class AudioFailure extends Failure {
  const AudioFailure({required super.message, super.code});
}

/// Lỗi liên quan đến phân tích phát âm AI
class PronunciationAnalysisFailure extends Failure {
  const PronunciationAnalysisFailure({required super.message, super.code});
}

/// Lỗi liên quan đến quyền truy cập (microphone, storage, notification)
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// Lỗi liên quan đến xác thực người dùng
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Lỗi không xác định
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Đã xảy ra lỗi không xác định',
    super.code,
  });
}
