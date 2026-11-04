import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../dao/user_dao.dart';
import '../mappers/user_mapper.dart';

/// Implementation của [UserRepository] sử dụng [UserDao] (Floor ORM)
class UserRepositoryImpl implements UserRepository {
  final UserDao _userDao;

  UserRepositoryImpl({required UserDao userDao}) : _userDao = userDao;

  @override
  Future<User?> getUserById(String id) async {
    final entity = await _userDao.findUserById(id);
    if (entity == null) return null;
    return UserMapper.fromEntity(entity);
  }

  @override
  Future<List<User>> getAllUsers() async {
    final entities = await _userDao.findAllUsers();
    return entities.map((e) => UserMapper.fromEntity(e)).toList();
  }

  @override
  Future<void> saveUser(User user) async {
    final entity = UserMapper.toEntity(user);
    final existing = await _userDao.findUserById(user.id);
    if (existing != null) {
      await _userDao.updateUser(entity);
    } else {
      await _userDao.insertUser(entity);
    }
  }

  @override
  Future<void> updateUser(User user) async {
    final entity = UserMapper.toEntity(user);
    await _userDao.updateUser(entity);
  }

  @override
  Future<void> deleteUser(String id) async {
    final entity = await _userDao.findUserById(id);
    if (entity != null) {
      await _userDao.deleteUser(entity);
    }
  }

  @override
  Future<void> updateStreak(
    String userId,
    int currentStreak,
    int longestStreak,
    DateTime lastPracticeDate,
  ) async {
    await _userDao.updateStreak(
      userId,
      currentStreak,
      longestStreak,
      lastPracticeDate.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> updateDailyGoal(String userId, int minutes) async {
    await _userDao.updateDailyGoal(userId, minutes);
  }

  @override
  Future<void> updateNotificationSettings(
    String userId,
    String time,
    bool enabled,
  ) async {
    await _userDao.updateNotificationSettings(
      userId,
      time,
      enabled ? 1 : 0,
    );
  }
}
