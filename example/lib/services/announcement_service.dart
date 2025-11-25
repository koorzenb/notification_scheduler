import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class that encapsulates all AnnouncementScheduler operations
/// Follows the Service/Repository pattern to separate data access from UI
class AnnouncementService {
  AnnouncementScheduler? _scheduler;

  bool get isInitialized => _scheduler != null;

  Stream<AnnouncementStatus>? get statusStream => _scheduler?.statusStream;

  /// Check and request notification permissions
  Future<bool> checkAndRequestNotificationPermissions() async {
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
      return false;
    }

    final isGranted = status.isGranted;
    return isGranted;
  }

  /// Initialize the announcement scheduler with default configuration
  Future<void> initialize() async {
    // Check notification permissions first
    final hasPermission = await checkAndRequestNotificationPermissions();

    if (!hasPermission) {
      debugPrint(
        '[AnnouncementService] Cannot initialize scheduler - notification permission not granted',
      );
      throw Exception('Notification permission not granted');
    }

    _scheduler = await AnnouncementScheduler.initialize(
      config: AnnouncementConfig(
        enableTTS: true,
        ttsRate: 0.5,
        ttsPitch: 1.0,
        ttsVolume: 1.0,
        enableDebugLogging: true,
        forceTimezone: true, // Use the timezone from settings
        timezoneLocation: 'America/Halifax',
        notificationConfig: NotificationConfig(
          channelId: 'example_announcements',
          channelName: 'Example Announcements',
          channelDescription: 'Example scheduled announcements',
        ),
        validationConfig: const ValidationConfig(
          maxNotificationsPerDay: 5,
          maxScheduledNotifications: 20,
        ),
      ),
    );
  }

  /// Schedule predefined example announcements
  Future<void> scheduleExampleAnnouncements() async {
    if (_scheduler == null) {
      throw Exception('Scheduler not initialized');
    }

    // Schedule a daily morning motivation
    await _scheduler!.scheduleAnnouncement(
      content: 'Good morning! Time to start your day with positive energy!',
      announcementTime: const TimeOfDay(hour: 8, minute: 0),
      recurrence: RecurrencePattern.daily,
      metadata: {'type': 'motivation', 'category': 'morning'},
    );

    // Schedule a weekday work reminder
    await _scheduler!.scheduleAnnouncement(
      content: 'Don\'t forget to review your daily goals and priorities.',
      announcementTime: const TimeOfDay(hour: 9, minute: 30),
      recurrence: RecurrencePattern.weekdays,
      metadata: {'type': 'productivity', 'category': 'work'},
    );

    // Schedule a one-time reminder
    await _scheduler!.scheduleOneTimeAnnouncement(
      content:
          'This is a one-time announcement scheduled for 5 seconds from now.',
      dateTime: DateTime.now().add(const Duration(seconds: 5)),
      metadata: {'type': 'reminder', 'category': 'test'},
    );
  }

  /// Cancel all scheduled announcements
  Future<void> cancelAllAnnouncements() async {
    if (_scheduler == null) {
      throw Exception('Scheduler not initialized');
    }
    await _scheduler!.cancelScheduledAnnouncements();
  }

  /// Get all scheduled announcements
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    if (_scheduler == null) {
      throw Exception('Scheduler not initialized');
    }
    return await _scheduler!.getScheduledAnnouncements();
  }

  /// Dispose of the scheduler resources
  void dispose() {
    _scheduler?.dispose();
    _scheduler = null;
  }
}
