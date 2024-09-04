import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class SecureStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save data to secure storage
  Future<void> saveData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Failed to save data securely: $e');
    }
  }

  // Load data from secure storage
  Future<String?> loadData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw Exception('Failed to load data securely: $e');
    }
  }

  // Delete data from secure storage
  Future<void> deleteData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete data securely: $e');
    }
  }

  // Clear all data from secure storage
  Future<void> clear() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear secure storage: $e');
    }
  }
}