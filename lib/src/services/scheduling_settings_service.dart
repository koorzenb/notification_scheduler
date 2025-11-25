import '../models/recurrence_pattern.dart';
import 'storage_service.dart';

/// Service for managing announcement scheduling settings within the package.
///
/// This service handles the persistence and retrieval of scheduling-related
/// configuration independently of the main app's settings service.
class SchedulingSettingsService {
  final IStorageService _storage;

  SchedulingSettingsService(this._storage);

  // Announcement time settings
  Future<int?> getAnnouncementHour() => _storage.get<int>('announcementHour');
  Future<void> setAnnouncementHour(int hour) =>
      _storage.set('announcementHour', hour);

  Future<int?> getAnnouncementMinute() =>
      _storage.get<int>('announcementMinute');
  Future<void> setAnnouncementMinute(int minute) =>
      _storage.set('announcementMinute', minute);

  Future<void> setAnnouncementTime(int hour, int minute) async {
    await setAnnouncementHour(hour);
    await setAnnouncementMinute(minute);
  }

  // Recurring announcement settings
  Future<bool> getIsRecurring() async =>
      await _storage.get<bool>('isRecurring') ?? false;

  Future<void> setIsRecurring(bool isRecurring) =>
      _storage.set('isRecurring', isRecurring);

  /// Pause/resume recurring without losing configuration
  Future<bool> getIsRecurringPaused() async =>
      await _storage.get<bool>('isRecurringPaused') ?? false;
  Future<void> setIsRecurringPaused(bool isPaused) =>
      _storage.set('isRecurringPaused', isPaused);

  /// Check if recurring is enabled and not paused
  Future<bool> getIsRecurringActive() async {
    final isRecurring = await getIsRecurring();
    final isPaused = await getIsRecurringPaused();
    return isRecurring && !isPaused;
  }

  Future<RecurrencePattern> getRecurrencePattern() async {
    final patternIndex = await _storage.get<int>('recurrencePattern');
    if (patternIndex == null ||
        patternIndex >= RecurrencePattern.values.length) {
      return RecurrencePattern.daily; // Default pattern
    }
    return RecurrencePattern.values[patternIndex];
  }

  Future<void> setRecurrencePattern(RecurrencePattern pattern) =>
      _storage.set('recurrencePattern', pattern.index);

  Future<List<int>> getRecurrenceDays() async {
    final days = await _storage.get<List<dynamic>>('recurrenceDays');
    if (days == null) {
      // Return default days for the current pattern
      final pattern = await getRecurrencePattern();
      return pattern.defaultDays;
    }
    return days.cast<int>();
  }

  Future<void> setRecurrenceDays(List<int> days) =>
      _storage.set('recurrenceDays', days);

  /// Set complete recurring configuration at once
  Future<void> setRecurringConfig({
    required bool isRecurring,
    RecurrencePattern pattern = RecurrencePattern.daily,
    List<int>? customDays,
  }) async {
    await setIsRecurring(isRecurring);
    await setRecurrencePattern(pattern);

    // Set custom days if provided, otherwise use pattern defaults
    final daysToSet = customDays ?? pattern.defaultDays;
    await setRecurrenceDays(daysToSet);
  }

  // Scheduled times persistence
  // Maps notification ID to scheduled time in milliseconds since epoch

  Future<void> setScheduledTime(
    int notificationId,
    DateTime scheduledTime,
  ) async {
    final times = await getScheduledTimes();
    times[notificationId.toString()] = scheduledTime.millisecondsSinceEpoch;
    await _storage.set('scheduledTimes', times);
  }

  Future<DateTime?> getScheduledTime(int notificationId) async {
    final times = await getScheduledTimes();
    final millis = times[notificationId.toString()];
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<Map<String, int>> getScheduledTimes() async {
    final data = await _storage.get<Map<dynamic, dynamic>>('scheduledTimes');
    if (data == null) return {};
    return data.map((key, value) => MapEntry(key.toString(), value as int));
  }

  Future<void> setScheduledTimes(Map<int, DateTime> scheduledTimes) async {
    final times = scheduledTimes.map(
      (key, value) => MapEntry(key.toString(), value.millisecondsSinceEpoch),
    );
    await _storage.set('scheduledTimes', times);
  }

  Future<void> clearScheduledTimes() async {
    await _storage.remove('scheduledTimes');
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    await _storage.clear();
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _storage.dispose();
  }
}
