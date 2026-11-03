/// Các exception tùy chỉnh cho ứng dụng Articulation
/// Được ném ra ở tầng Data và bắt ở tầng Repository để chuyển thành Failure
library;

/// Exception khi thao tác với cơ sở dữ liệu thất bại
class DatabaseException implements Exception {
  final String message;
  final dynamic cause;

  const DatabaseException({required this.message, this.cause});

  @override
  String toString() => 'DatabaseException: $message (cause: $cause)';
}

/// Exception khi gọi API mạng thất bại
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({required this.message, this.statusCode});

  @override
  String toString() => 'NetworkException: $message (status: $statusCode)';
}

/// Exception khi xử lý audio/ghi âm thất bại
class AudioException implements Exception {
  final String message;
  final dynamic cause;

  const AudioException({required this.message, this.cause});

  @override
  String toString() => 'AudioException: $message';
}

/// Exception khi phân tích phát âm thất bại
class PronunciationException implements Exception {
  final String message;
  final dynamic cause;

  const PronunciationException({required this.message, this.cause});

  @override
  String toString() => 'PronunciationException: $message';
}

/// Exception khi không có quyền truy cập cần thiết
class PermissionException implements Exception {
  final String message;
  final String permissionType;

  const PermissionException({
    required this.message,
    required this.permissionType,
  });

  @override
  String toString() =>
      'PermissionException: $message (permission: $permissionType)';
}
