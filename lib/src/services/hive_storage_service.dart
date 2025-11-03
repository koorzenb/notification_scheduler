import 'package:hive_flutter/hive_flutter.dart';

import 'storage_service.dart';

/// Default implementation of IStorageService using Hive.
///
/// This implementation uses the factory constructor pattern to ensure
/// proper async initialization before the object can be used. This eliminates
/// the need for null checks and provides better performance.
///
/// ## Usage
///
/// ```dart
/// // Create an initialized storage service
/// final storage = await HiveStorageService.create();
///
/// // Use immediately without additional initialization
/// await storage.set('key', 'value');
/// final value = await storage.get<String>('key');
/// ```
///
/// ## Benefits
///
/// - No null checks needed in methods
/// - Guaranteed initialization before use
/// - Better performance (no repeated initialization checks)
/// - Cleaner API - no separate initialize() call needed
class HiveStorageService implements IStorageService {
  final Box _box;

  // Private constructor that requires an already opened box
  HiveStorageService._(this._box);

  /// Factory constructor that handles async initialization.
  ///
  /// This method:
  /// 1. Initializes Hive if not already initialized
  /// 2. Opens the specified box
  /// 3. Returns a fully ready-to-use HiveStorageService instance
  ///
  /// [boxName] - The name of the Hive box to use for storage
  static Future<HiveStorageService> create({
    String boxName = 'announcement_scheduler',
  }) async {
    await Hive.initFlutter();
    final box = await Hive.openBox(boxName);
    return HiveStorageService._(box);
  }

  @override
  Future<void> initialize() async {
    // Already initialized in factory constructor
    // This method is kept for interface compatibility but does nothing
  }

  @override
  Future<T?> get<T>(String key) async {
    return _box.get(key) as T?;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _box.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _box.keys.cast<String>().toList();
  }

  @override
  Future<void> dispose() async {
    await _box.close();
  }
}
