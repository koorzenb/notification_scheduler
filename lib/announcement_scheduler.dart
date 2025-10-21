/// A Flutter package for scheduling text-to-speech announcements.
///
/// This package provides a simple API for scheduling both one-time and
/// recurring text-to-speech announcements using local notifications.
/// It supports various recurrence patterns including daily, weekdays,
/// weekends, and custom day selections.
///
/// Example usage:
/// ```dart
/// import 'package:announcement_scheduler/announcement_scheduler.dart';
///
/// final scheduler = await AnnouncementScheduler.initialize(
///   config: AnnouncementConfig(
///     notificationConfig: NotificationConfig(
///       channelId: 'my_announcements',
///       channelName: 'My Announcements',
///       channelDescription: 'Scheduled text-to-speech announcements',
///     ),
///   ),
/// );
///
/// await scheduler.scheduleAnnouncement(
///   content: 'Good morning! Time for your daily reminder.',
///   announcementTime: TimeOfDay(hour: 8, minute: 0),
///   recurrence: RecurrencePattern.daily,
/// );
/// ```
library;

// Re-export commonly needed types from dependencies
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show Importance, Priority;

// Export public API
export 'src/announcement_scheduler.dart';
export 'src/models/announcement_config.dart';
export 'src/models/announcement_exceptions.dart';
export 'src/models/announcement_status.dart';
export 'src/models/notification_config.dart';
export 'src/models/recurrence_pattern.dart';
export 'src/models/scheduled_announcement.dart';
export 'src/models/validation_config.dart';
