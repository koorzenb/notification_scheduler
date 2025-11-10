import 'package:announcement_scheduler/announcement_scheduler.dart';

/// Service class that encapsulates all AnnouncementScheduler operations
/// Follows the Service/Repository pattern to separate data access from UI
class AnnouncementService {
  AnnouncementScheduler? _scheduler;

  bool get isInitialized => _scheduler != null;

  Stream<AnnouncementStatus>? get statusStream => _scheduler?.statusStream;

  /// Initialize the announcement scheduler with default configuration
  Future<void> initialize() async {
    _scheduler = await AnnouncementScheduler.initialize(
      config: AnnouncementConfig(
        enableTTS: true,
        ttsRate: 0.5,
        ttsPitch: 1.0,
        ttsVolume: 1.0,
        enableDebugLogging: true,
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
  Future<List<String>> scheduleExampleAnnouncements() async {
    if (_scheduler == null) {
      throw Exception('Scheduler not initialized');
    }

    final ids = <String>[];

    // // Schedule a daily morning motivation
    // final dailyId = await _scheduler!.scheduleAnnouncement(
    //   content: 'Good morning! Time to start your day with positive energy!',
    //   announcementTime: const TimeOfDay(hour: 8, minute: 0),
    //   recurrence: RecurrencePattern.daily,
    //   metadata: {'type': 'motivation', 'category': 'morning'},
    // );
    // ids.add(dailyId);

    // // Schedule a weekday work reminder
    // final weekdayId = await _scheduler!.scheduleAnnouncement(
    //   content: 'Don\'t forget to review your daily goals and priorities.',
    //   announcementTime: const TimeOfDay(hour: 9, minute: 30),
    //   recurrence: RecurrencePattern.weekdays,
    //   metadata: {'type': 'productivity', 'category': 'work'},
    // );
    // ids.add(weekdayId);

    // Schedule a one-time reminder
    final oneTimeId = await _scheduler!.scheduleOneTimeAnnouncement(
      content:
          'This is a one-time announcement scheduled for 5 seconds from now.',
      dateTime: DateTime.now().add(const Duration(seconds: 5)),
      metadata: {'type': 'reminder', 'category': 'test'},
    );
    ids.add(oneTimeId);

    return ids;
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
