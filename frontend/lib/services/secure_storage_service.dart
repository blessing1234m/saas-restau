import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  /// Save a string value in secure storage
  static Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Retrieve a string value from secure storage
  static Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a value from secure storage
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all data from secure storage
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage
  static Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}
