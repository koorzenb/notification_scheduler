/// A Flutter package for scheduling text-to-speech notifications.
///
/// This package provides a simple API for scheduling both one-time and
/// recurring text-to-speech notifications using local notifications.
/// It supports various recurrence patterns including daily, weekdays,
/// weekends, and custom day selections.
///
/// Example usage:
/// ```dart
/// import 'package:notification_scheduler/notification_scheduler.dart';
///
/// final scheduler = await notificationScheduler.create(
///   config: notificationConfig(
///     notificationConfig: NotificationConfig(
///       channelId: 'my_notifications',
///       channelName: 'My notifications',
///       channelDescription: 'Scheduled text-to-speech notifications',
///     ),
///   ),
/// );
///
/// await scheduler.scheduleNotification(
///   content: 'Good morning! Time for your daily reminder.',
///   notificationTime: TimeOfDay(hour: 8, minute: 0),
///   recurrence: RecurrencePattern.daily,
/// );
/// ```
library;

// Re-export commonly needed types from dependencies
export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show Importance, Priority;

export 'src/models/announcement_config.dart';
export 'src/models/announcement_exceptions.dart';
export 'src/models/notification_config.dart';
export 'src/models/notification_status.dart';
export 'src/models/recurrence_pattern.dart';
export 'src/models/scheduled_notification.dart';
export 'src/models/validation_config.dart';
// Export public API
export 'src/notification_scheduler.dart';
export 'src/services/notification_service.dart';
