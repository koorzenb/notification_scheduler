import 'package:flutter/foundation.dart';

import '../models/scheduled_notification.dart';
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

  // Scheduled announcements persistence
  // Stores complete ScheduledAnnouncement objects as JSON

  /// Retrieves all scheduled announcements from storage
  ///
  /// Returns an empty list if no announcements are stored or if
  /// deserialization fails. Handles deserialization errors gracefully
  /// by logging and skipping invalid entries.
  Future<List<ScheduledNotification>> getScheduledAnnouncements() async {
    try {
      final data = await _storage.get<List<dynamic>>('scheduledAnnouncements');
      if (data == null) return [];

      final announcements = <ScheduledNotification>[];
      for (final item in data) {
        try {
          if (item is Map<dynamic, dynamic>) {
            // Convert to Map<String, dynamic> for fromJson
            final jsonMap = Map<String, dynamic>.from(item);
            announcements.add(ScheduledNotification.fromJson(jsonMap));
          }
        } catch (e) {
          // Skip invalid entries, continue processing others
          // In production, this could be logged for debugging
          continue;
        }
      }
      return announcements;
    } catch (e) {
      // If storage retrieval fails, return empty list
      return [];
    }
  }

  /// Persists a list of scheduled announcements to storage
  ///
  /// Serializes each [ScheduledNotification] to JSON and stores the
  /// resulting list. Replaces any previously stored announcements.
  Future<void> setScheduledAnnouncements(
    List<ScheduledNotification> announcements,
  ) async {
    final jsonList = announcements.map((a) => a.toJson()).toList();
    await _storage.set('scheduledAnnouncements', jsonList);
  }

  /// Adds a single scheduled announcement to storage
  ///
  /// Retrieves the current list, appends the new announcement, and
  /// stores the updated list. This is more efficient than loading
  /// and replacing the entire list externally.
  Future<void> addScheduledAnnouncement(
    ScheduledNotification announcement,
  ) async {
    final currentAnnouncements = await getScheduledAnnouncements();
    currentAnnouncements.add(announcement);
    await setScheduledAnnouncements(currentAnnouncements);
  }

  /// Removes a scheduled announcement from storage by ID
  ///
  /// Retrieves the current list, filters out the announcement with
  /// the matching ID, and stores the updated list. No error if ID not found.
  Future<void> removeScheduledAnnouncement(int announcementId) async {
    final currentAnnouncements = await getScheduledAnnouncements();
    final filteredAnnouncements = currentAnnouncements
        .where((announcement) => announcement.id != announcementId)
        .toList();
    await setScheduledAnnouncements(filteredAnnouncements);
  }

  /// Removes multiple scheduled announcements from storage by IDs (bulk removal)
  ///
  /// Retrieves the current list, filters out announcements with IDs in the
  /// provided list, and stores the updated list. Non-existing IDs are ignored.
  /// This is more efficient than calling removeScheduledAnnouncement multiple times.
  Future<void> removeScheduledAnnouncements(List<int> announcementIds) async {
    final currentAnnouncements = await getScheduledAnnouncements();
    final filteredAnnouncements = currentAnnouncements
        .where((announcement) => !announcementIds.contains(announcement.id))
        .toList();
    await setScheduledAnnouncements(filteredAnnouncements);
  }

  /// Clear all settings
  ///
  /// **Note**: This method is currently unused in the core logic but kept for
  /// API completeness and potential future use (e.g., "Factory Reset" feature).
  @visibleForTesting
  Future<void> clearSettings() async {
    await _storage.remove('scheduledAnnouncements');
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _storage.dispose();
  }
}
