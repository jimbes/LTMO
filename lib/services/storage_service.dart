import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pma_flutter/utils/constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final id = await _storage.read(key: StorageKeys.userId);
    return id != null ? int.parse(id) : null;
  }

  Future<void> saveCoupleId(int coupleId) async {
    await _storage.write(
      key: StorageKeys.coupleId,
      value: coupleId.toString(),
    );
  }

  Future<int?> getCoupleId() async {
    final id = await _storage.read(key: StorageKeys.coupleId);
    return id != null ? int.parse(id) : null;
  }

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: StorageKeys.userData, value: userData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: StorageKeys.userData);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
