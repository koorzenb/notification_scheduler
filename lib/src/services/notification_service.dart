import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/announcement_config.dart';
import '../models/notification_status.dart';
import '../models/recurrence_pattern.dart';
import '../models/scheduled_notification.dart';
import '../notification_scheduler.dart';

/// Service class that encapsulates all [NotificationScheduler] operations.
///
/// Follows the Service/Repository pattern to separate data access from UI.
/// This service handles permission requests before initializing the scheduler.
class NotificationService {
  final NotificationScheduler _scheduler;

  // Private constructor
  NotificationService._(this._scheduler);

  /// Create and initialize the [NotificationService].
  ///
  /// This method will check for notification permissions and request them if needed.
  /// Throws an [Exception] if permissions are not granted.
  static Future<NotificationService> create({
    required AnnouncementConfig config,
  }) async {
    // Check notification permissions first
    final hasPermission = await _checkAndRequestNotificationPermissions();

    if (!hasPermission) {
      debugPrint(
        '[AnnouncementService] Cannot initialize scheduler - notification permission not granted',
      );
      throw Exception('Notification permission not granted');
    }

    final scheduler = await NotificationScheduler.create(config: config);

    return NotificationService._(scheduler);
  }

  /// Stream of status updates from the scheduler.
  Stream<NotificationStatus> get statusStream => _scheduler.statusStream;

  /// Check and request notification permissions.
  static Future<bool> _checkAndRequestNotificationPermissions() async {
    // Check if notification permission is granted
    var status = await Permission.notification.status;

    if (status.isDenied) {
      debugPrint('[AnnouncementService] Requesting notification permission...');
      status = await Permission.notification.request();
      debugPrint('[AnnouncementService] Permission request result: $status');
    }

    if (status.isPermanentlyDenied) {
      debugPrint(
        '[AnnouncementService] Notification permission permanently denied. Opening app settings...',
      );
      // User has permanently denied permission, open app settings
      await openAppSettings();
      return false;
    }

    final isGranted = status.isGranted;
    return isGranted;
  }

  /// Schedule a one-time announcement.
  Future<int> scheduleOnceOff({
    required String content,
    required DateTime dateTime,
    Map<String, dynamic>? metadata,
  }) async {
    return await _scheduler.scheduleOneTimeAnnouncement(
      content: content,
      dateTime: dateTime,
      metadata: metadata,
    );
  }

  /// Schedule a daily recurrent announcement.
  Future<int> scheduleDaily({
    required String content,
    required TimeOfDay time,
    Map<String, dynamic>? metadata,
  }) async {
    return await _scheduler.scheduleAnnouncement(
      content: content,
      announcementTime: time,
      recurrence: RecurrencePattern.daily,
      metadata: metadata,
    );
  }

  /// Schedule a weekly announcement on specific days.
  ///
  /// [weekdays] should be a list of integers where 1=Monday, 7=Sunday.
  Future<int> scheduleWeekly({
    required String content,
    required TimeOfDay time,
    required List<int> weekdays,
    Map<String, dynamic>? metadata,
  }) async {
    return await _scheduler.scheduleAnnouncement(
      content: content,
      announcementTime: time,
      recurrence: RecurrencePattern.custom,
      customDays: weekdays,
      metadata: metadata,
    );
  }

  /// Cancel all scheduled announcements.
  Future<void> cancelAllAnnouncements() async {
    await _scheduler.cancelScheduledAnnouncements();
  }

  /// Get all scheduled announcements.
  Future<List<ScheduledNotification>> getScheduledAnnouncements() async {
    return await _scheduler.getScheduledAnnouncements();
  }

  /// Dispose of the scheduler resources.
  void dispose() {
    _scheduler.dispose();
  }
}
