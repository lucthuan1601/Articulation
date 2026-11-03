/// Cơ sở dữ liệu chính của ứng dụng Articulation.
///
/// Sử dụng Floor ORM (SQLite) để quản lý lưu trữ cục bộ.
/// File này định nghĩa lớp [AppDatabase] với pattern Singleton
/// để đảm bảo chỉ có một kết nối cơ sở dữ liệu duy nhất
/// trong suốt vòng đời ứng dụng.
///
/// Các bảng (entities):
/// - [UserEntity] - Thông tin người dùng
/// - [LessonEntity] - Bài học phát âm
/// - [PracticeSessionEntity] - Phiên luyện tập
/// - [PronunciationResultEntity] - Kết quả phát âm
///
/// Các DAO:
/// - [UserDao] - Truy vấn dữ liệu người dùng
/// - [LessonDao] - Truy vấn dữ liệu bài học
/// - [PracticeSessionDao] - Truy vấn dữ liệu phiên luyện tập
/// - [PronunciationResultDao] - Truy vấn dữ liệu kết quả phát âm
library;

import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

// Import các Entity (model)
import 'package:articulation/features/habit_tracking/data/models/user_entity.dart';
import 'package:articulation/features/pronunciation/data/models/lesson_entity.dart';
import 'package:articulation/features/habit_tracking/data/models/practice_session_entity.dart';
import 'package:articulation/features/pronunciation/data/models/pronunciation_result_entity.dart';

// Import các DAO
import 'package:articulation/features/habit_tracking/data/dao/user_dao.dart';
import 'package:articulation/features/pronunciation/data/dao/lesson_dao.dart';
import 'package:articulation/features/habit_tracking/data/dao/practice_session_dao.dart';
import 'package:articulation/features/pronunciation/data/dao/pronunciation_result_dao.dart';

// File được tạo tự động bởi Floor generator (floor_generator).
// Chạy lệnh: dart run build_runner build
part 'app_database.g.dart';

/// Lớp cơ sở dữ liệu chính của ứng dụng Articulation.
///
/// Sử dụng Floor ORM với SQLite làm engine lưu trữ cục bộ.
/// Quản lý 4 bảng dữ liệu chính và cung cấp 4 DAO
/// để thực hiện các thao tác CRUD và truy vấn dữ liệu.
///
/// Sử dụng pattern Singleton thông qua [getInstance] để đảm bảo
/// chỉ có một instance duy nhất trong toàn bộ ứng dụng.
///
/// ### Cách sử dụng:
/// ```dart
/// final database = await AppDatabase.getInstance();
/// final users = await database.userDao.findAllUsers();
/// ```
///
/// ### Tạo mã nguồn tự động:
/// ```bash
/// dart run build_runner build
/// ```
@Database(
  version: 1,
  entities: [
    UserEntity,
    LessonEntity,
    PracticeSessionEntity,
    PronunciationResultEntity,
  ],
)
abstract class AppDatabase extends FloorDatabase {
  /// Instance Singleton của cơ sở dữ liệu.
  ///
  /// Được khởi tạo lần đầu khi gọi [getInstance] và tái sử dụng
  /// cho tất cả các lần gọi tiếp theo.
  static AppDatabase? _instance;

  /// DAO quản lý dữ liệu người dùng.
  ///
  /// Cung cấp các phương thức: tìm kiếm, thêm, cập nhật, xóa người dùng,
  /// cập nhật streak, mục tiêu hàng ngày, cài đặt thông báo.
  UserDao get userDao;

  /// DAO quản lý dữ liệu bài học phát âm.
  ///
  /// Cung cấp các phương thức: tìm kiếm, lọc theo loại/mức độ/danh mục,
  /// thêm đơn lẻ hoặc hàng loạt, cập nhật, xóa bài học.
  LessonDao get lessonDao;

  /// DAO quản lý dữ liệu phiên luyện tập.
  ///
  /// Cung cấp các phương thức: tìm kiếm, lọc theo người dùng/thời gian,
  /// thống kê tổng thời gian/điểm trung bình/số lượng phiên.
  PracticeSessionDao get practiceSessionDao;

  /// DAO quản lý dữ liệu kết quả phát âm.
  ///
  /// Cung cấp các phương thức: tìm kiếm, lọc theo phiên/người dùng/bài học,
  /// thống kê độ chính xác trung bình, điểm cao nhất, kết quả gần đây.
  PronunciationResultDao get pronunciationResultDao;

  /// Lấy instance Singleton của cơ sở dữ liệu.
  ///
  /// Nếu chưa được khởi tạo, tạo mới bằng Floor database builder
  /// với tên file 'articulation.db'.
  /// Các lần gọi tiếp theo sẽ trả về cùng instance đã tạo.
  ///
  /// Trả về [Future<AppDatabase>] - instance duy nhất của cơ sở dữ liệu.
  ///
  /// ### Ví dụ:
  /// ```dart
  /// // Lấy instance cơ sở dữ liệu
  /// final db = await AppDatabase.getInstance();
  ///
  /// // Sử dụng các DAO
  /// final user = await db.userDao.findUserById('user-123');
  /// final lessons = await db.lessonDao.findAllLessons();
  /// ```
  static Future<AppDatabase> getInstance() async {
    _instance ??= await $FloorAppDatabase
        .databaseBuilder('articulation.db')
        .build();
    return _instance!;
  }
}
