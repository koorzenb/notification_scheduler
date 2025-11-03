/// Abstract interface for storage operations to decouple the package from
/// specific storage implementations like Hive or shared preferences.
///
/// This allows the package to be storage-agnostic and lets consumers provide
/// their preferred storage implementation.
abstract class IStorageService {
  /// Initialize the storage service
  Future<void> initialize();

  /// Get a value by key
  Future<T?> get<T>(String key);

  /// Set a value by key
  Future<void> set<T>(String key, T value);

  /// Remove a value by key
  Future<void> remove(String key);

  /// Clear all stored values
  Future<void> clear();

  /// Check if a key exists
  Future<bool> containsKey(String key);

  /// Get all keys
  Future<List<String>> getAllKeys();

  /// Dispose of any resources
  Future<void> dispose();
}
