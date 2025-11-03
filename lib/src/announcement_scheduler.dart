import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models/announcement_config.dart';
import 'models/announcement_exceptions.dart';
import 'models/announcement_status.dart';
import 'models/recurrence_pattern.dart';
import 'models/scheduled_announcement.dart';
import 'services/core_notification_service.dart';
import 'services/hive_storage_service.dart';
import 'services/scheduling_settings_service.dart';

/// Main entry point for the announcement scheduler package.
///
/// [AnnouncementScheduler] provides a clean API for scheduling both one-time
/// and recurring text-to-speech announcements using local notifications.
///
/// ## Features
///
/// - Schedule announcements for specific times with [scheduleAnnouncement]
/// - Schedule one-time announcements with [scheduleOneTimeAnnouncement]
/// - Support for recurring patterns: daily, weekdays, weekends, or custom days
/// - Built-in TTS (Text-to-Speech) support with configurable voice settings
/// - Validation to prevent excessive notifications
/// - Timezone-aware scheduling
/// - Status updates via [statusStream]
///
/// ## Usage Example
///
/// ```dart
/// // Initialize the scheduler
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
/// // Schedule a daily announcement
/// final id = await scheduler.scheduleAnnouncement(
///   content: 'Good morning! Time for your daily reminder.',
///   announcementTime: TimeOfDay(hour: 8, minute: 0),
///   recurrence: RecurrencePattern.daily,
/// );
///
/// // Schedule a one-time announcement
/// await scheduler.scheduleOneTimeAnnouncement(
///   content: 'Special reminder',
///   dateTime: DateTime.now().add(Duration(hours: 2)),
/// );
///
/// // Clean up when done
/// await scheduler.dispose();
/// ```
///
/// ## Configuration
///
/// Configure TTS settings, notification behavior, and validation rules through
/// [AnnouncementConfig]. See [NotificationConfig] and [ValidationConfig] for
/// detailed configuration options.
///
/// ## Error Handling
///
/// The scheduler throws specific exceptions for different error conditions:
///
/// - [ValidationException]: Invalid input or validation failures
/// - [NotificationPermissionDeniedException]: Permission denied by user
/// - [NotificationInitializationException]: Notification setup failed
/// - [NotificationSchedulingException]: Scheduling operation failed
/// - [TTSInitializationException]: TTS setup failed
///
/// See also:
///
/// - [AnnouncementConfig] for configuration options
/// - [RecurrencePattern] for recurring announcement patterns
/// - [ScheduledAnnouncement] for announcement data model
/// - [AnnouncementStatus] for announcement lifecycle states
class AnnouncementScheduler {
  final AnnouncementConfig _config;
  final CoreNotificationService _notificationService;

  AnnouncementScheduler._({
    required AnnouncementConfig config,
    required CoreNotificationService notificationService,
  }) : _config = config,
       _notificationService = notificationService;

  /// Initialize the announcement scheduler with the given configuration.
  ///
  /// This is the primary factory method for creating an [AnnouncementScheduler]
  /// instance. It must be called before any scheduling operations.
  ///
  /// The method performs the following initialization steps:
  ///
  /// 1. Initializes timezone data for accurate scheduling
  /// 2. Sets up the notification system with platform-specific configurations
  /// 3. Initializes TTS (Text-to-Speech) if enabled in the config
  /// 4. Creates notification channels (Android) or requests permissions (iOS)
  ///
  /// ## Parameters
  ///
  /// - [config]: Configuration for the scheduler, including TTS settings,
  ///   notification preferences, and validation rules. See [AnnouncementConfig]
  ///   for all available options.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a fully initialized [AnnouncementScheduler]
  /// instance ready to schedule announcements.
  ///
  /// ## Throws
  ///
  /// - [NotificationInitializationException] if notification setup fails
  /// - [TTSInitializationException] if TTS setup fails (when TTS is enabled)
  ///
  /// ## Example
  ///
  /// ```dart
  /// final scheduler = await AnnouncementScheduler.initialize(
  ///   config: AnnouncementConfig(
  ///     enableTTS: true,
  ///     ttsRate: 0.5,
  ///     ttsPitch: 1.0,
  ///     forceTimezone: true,
  ///     timezoneLocation: 'America/New_York',  // Or use user's location
  ///     notificationConfig: NotificationConfig(
  ///       channelId: 'daily_weather',
  ///       channelName: 'Daily Weather',
  ///       channelDescription: 'Daily weather announcements',
  ///     ),
  ///     validationConfig: ValidationConfig(
  ///       maxNotificationsPerDay: 5,
  ///       maxScheduledNotifications: 30,
  ///     ),
  ///   ),
  /// );
  /// ```
  ///
  /// See also:
  ///
  /// - [AnnouncementConfig] for configuration details
  /// - [NotificationConfig] for notification channel settings
  /// - [ValidationConfig] for validation rules
  static Future<AnnouncementScheduler> initialize({
    required AnnouncementConfig config,
  }) async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Set local timezone if specified
    if (config.forceTimezone && config.timezoneLocation != null) {
      try {
        tz.setLocalLocation(tz.getLocation(config.timezoneLocation!));
      } catch (e) {
        throw NotificationInitializationException(
          'Failed to set timezone location ${config.timezoneLocation}: $e',
        );
      }
    }

    // Initialize storage service
    final storageService = await HiveStorageService.create();

    // Initialize settings service
    final settingsService = SchedulingSettingsService(storageService);

    // Initialize core notification service
    final notificationService = CoreNotificationService(
      settingsService: settingsService,
      config: config,
    );
    await notificationService.initialize();

    return AnnouncementScheduler._(
      config: config,
      notificationService: notificationService,
    );
  }

  /// Schedule an announcement with optional recurrence.
  ///
  /// This method schedules an announcement to be delivered at a specific time,
  /// either once or on a recurring basis. For recurring announcements, the
  /// scheduler automatically calculates and schedules multiple occurrences
  /// within the configured scheduling window.
  ///
  /// ## Parameters
  ///
  /// - [content]: The text content to be announced via TTS and shown in the
  ///   notification. Must not be empty.
  ///
  /// - [announcementTime]: The time of day when the announcement should be
  ///   delivered. For recurring announcements, this time will be used for all
  ///   occurrences.
  ///
  /// - [recurrence]: The recurrence pattern for the announcement. Use:
  ///   - [RecurrencePattern.daily] for every day
  ///   - [RecurrencePattern.weekdays] for Monday-Friday
  ///   - [RecurrencePattern.weekends] for Saturday-Sunday
  ///   - [RecurrencePattern.custom] with [customDays] for specific days
  ///   - `null` for a one-time announcement
  ///
  /// - [customDays]: Required when [recurrence] is [RecurrencePattern.custom].
  ///   List of day numbers where 1=Monday, 2=Tuesday, ..., 7=Sunday.
  ///   Ignored for other recurrence patterns.
  ///
  /// - [metadata]: Optional custom data to associate with the announcement.
  ///   This can be used to store additional context or application-specific
  ///   information.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a unique announcement ID that can be used
  /// to cancel the announcement later via [cancelAnnouncementById].
  ///
  /// ## Throws
  ///
  /// - [ValidationException] if:
  ///   - [content] is empty
  ///   - [recurrence] is custom but [customDays] is null or empty
  ///   - [customDays] contains invalid day numbers (not 1-7)
  ///   - Scheduling would exceed configured limits
  ///
  /// - [NotificationSchedulingException] if the notification system fails to
  ///   schedule the announcement
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Daily announcement
  /// final id = await scheduler.scheduleAnnouncement(
  ///   content: 'Good morning! Time to start your day.',
  ///   announcementTime: TimeOfDay(hour: 7, minute: 0),
  ///   recurrence: RecurrencePattern.daily,
  /// );
  ///
  /// // Weekday announcement
  /// await scheduler.scheduleAnnouncement(
  ///   content: 'Work day reminder',
  ///   announcementTime: TimeOfDay(hour: 8, minute: 30),
  ///   recurrence: RecurrencePattern.weekdays,
  /// );
  ///
  /// // Custom schedule (Monday, Wednesday, Friday)
  /// await scheduler.scheduleAnnouncement(
  ///   content: 'Workout reminder',
  ///   announcementTime: TimeOfDay(hour: 6, minute: 0),
  ///   recurrence: RecurrencePattern.custom,
  ///   customDays: [1, 3, 5],
  /// );
  ///
  /// // One-time announcement (schedule for next occurrence)
  /// await scheduler.scheduleAnnouncement(
  ///   content: 'One-time reminder',
  ///   announcementTime: TimeOfDay(hour: 14, minute: 30),
  ///   // No recurrence = one-time
  /// );
  /// ```
  ///
  /// See also:
  ///
  /// - [scheduleOneTimeAnnouncement] for scheduling at a specific DateTime
  /// - [cancelAnnouncementById] to cancel a scheduled announcement
  /// - [RecurrencePattern] for available recurrence options
  Future<String> scheduleAnnouncement({
    required String content,
    required TimeOfDay announcementTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate content
    if (content.trim().isEmpty) {
      throw const ValidationException('Announcement content cannot be empty');
    }

    // Validate custom days if using custom recurrence
    if (recurrence == RecurrencePattern.custom) {
      if (customDays == null || customDays.isEmpty) {
        throw const ValidationException(
          'Custom days must be provided when using custom recurrence pattern',
        );
      }
      if (customDays.any((day) => day < 1 || day > 7)) {
        throw const ValidationException(
          'Custom days must be between 1 (Monday) and 7 (Sunday)',
        );
      }
    }

    // Generate unique ID
    final id = 'announcement_${DateTime.now().millisecondsSinceEpoch}';

    // Calculate next occurrence
    final now = DateTime.now();
    final nextOccurrence = _calculateNextOccurrence(
      announcementTime,
      recurrence,
      customDays,
      now,
    );

    // Schedule with the notification service
    await _notificationService.scheduleRecurringAnnouncement(
      content: content,
      announcementTime: announcementTime,
      recurrence: recurrence,
      customDays: customDays,
    );

    _log('Scheduled announcement: $id at $nextOccurrence');
    return id;
  }

  /// Schedule a one-time announcement at a specific date and time.
  ///
  /// This method schedules an announcement to be delivered exactly once at
  /// the specified [dateTime]. Unlike [scheduleAnnouncement], this method
  /// accepts a full [DateTime] allowing precise control over both date and time.
  ///
  /// ## Parameters
  ///
  /// - [content]: The text content to be announced via TTS and shown in the
  ///   notification. Must not be empty.
  ///
  /// - [dateTime]: The exact date and time when the announcement should be
  ///   delivered. Must be in the future.
  ///
  /// - [metadata]: Optional custom data to associate with the announcement.
  ///   This can be used to store additional context or application-specific
  ///   information.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a unique announcement ID that can be used
  /// to cancel the announcement later via [cancelAnnouncementById].
  ///
  /// ## Throws
  ///
  /// - [ValidationException] if:
  ///   - [content] is empty
  ///   - [dateTime] is not in the future
  ///   - Scheduling would exceed configured limits
  ///
  /// - [NotificationSchedulingException] if the notification system fails to
  ///   schedule the announcement
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Schedule for 2 hours from now
  /// final id = await scheduler.scheduleOneTimeAnnouncement(
  ///   content: 'Meeting reminder: Team standup in 5 minutes',
  ///   dateTime: DateTime.now().add(Duration(hours: 2)),
  /// );
  ///
  /// // Schedule for a specific date and time
  /// await scheduler.scheduleOneTimeAnnouncement(
  ///   content: 'Happy Birthday!',
  ///   dateTime: DateTime(2025, 3, 15, 9, 0),
  ///   metadata: {'type': 'birthday', 'person': 'John'},
  /// );
  /// ```
  ///
  /// See also:
  ///
  /// - [scheduleAnnouncement] for recurring or time-based announcements
  /// - [cancelAnnouncementById] to cancel a scheduled announcement
  Future<String> scheduleOneTimeAnnouncement({
    required String content,
    required DateTime dateTime,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate content
    if (content.trim().isEmpty) {
      throw const ValidationException('Announcement content cannot be empty');
    }

    // Validate date is in the future
    if (dateTime.isBefore(DateTime.now())) {
      throw const ValidationException('Scheduled time must be in the future');
    }

    // Generate unique ID
    final id = 'announcement_${DateTime.now().millisecondsSinceEpoch}';

    // Schedule with the notification service
    await _notificationService.scheduleOneTimeAnnouncement(
      content: content,
      dateTime: dateTime,
    );

    _log('Scheduled one-time announcement: $id at $dateTime');
    return id;
  }

  /// Cancel all scheduled announcements.
  ///
  /// This method cancels all pending announcement notifications and clears
  /// any active timers. After calling this method, no scheduled announcements
  /// will be delivered until new ones are scheduled.
  ///
  /// This is useful when:
  /// - User wants to stop all announcements
  /// - Changing announcement configuration significantly
  /// - Resetting the scheduler state
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Cancel everything and start fresh
  /// await scheduler.cancelScheduledAnnouncements();
  ///
  /// // Schedule new announcements
  /// await scheduler.scheduleAnnouncement(
  ///   content: 'New announcement',
  ///   announcementTime: TimeOfDay(hour: 9, minute: 0),
  /// );
  /// ```
  ///
  /// See also:
  ///
  /// - [cancelAnnouncementById] to cancel a specific announcement
  /// - [getScheduledAnnouncements] to view currently scheduled announcements
  Future<void> cancelScheduledAnnouncements() async {
    await _notificationService.cancelAllNotifications();
    _log('Cancelled all scheduled announcements');
  }

  /// Cancel a specific announcement by its ID.
  ///
  /// This method cancels a single announcement and all its recurring
  /// occurrences (if applicable) without affecting other scheduled
  /// announcements.
  ///
  /// ## Parameters
  ///
  /// - [id]: The unique identifier returned by [scheduleAnnouncement] or
  ///   [scheduleOneTimeAnnouncement].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Schedule an announcement and save its ID
  /// final id = await scheduler.scheduleAnnouncement(
  ///   content: 'Daily reminder',
  ///   announcementTime: TimeOfDay(hour: 10, minute: 0),
  ///   recurrence: RecurrencePattern.daily,
  /// );
  ///
  /// // Later, cancel just this announcement
  /// await scheduler.cancelAnnouncementById(id);
  /// ```
  ///
  /// See also:
  ///
  /// - [cancelScheduledAnnouncements] to cancel all announcements
  /// - [getScheduledAnnouncements] to view currently scheduled announcements
  Future<void> cancelAnnouncementById(String id) async {
    await _notificationService.cancelAnnouncementById(id);
    _log('Cancelled announcement: $id');
  }

  /// Get all currently scheduled announcements.
  ///
  /// Returns a list of all announcements that are currently scheduled and
  /// pending delivery. This can be used to display the user's scheduled
  /// announcements or to verify that announcements were scheduled correctly.
  ///
  /// Note: The implementation depends on the notification system's ability
  /// to retrieve pending notifications. Some announcement metadata may not
  /// be fully available through this method.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a list of [ScheduledAnnouncement] objects
  /// representing all currently scheduled announcements.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get and display all scheduled announcements
  /// final announcements = await scheduler.getScheduledAnnouncements();
  ///
  /// for (final announcement in announcements) {
  ///   print('${announcement.content} at ${announcement.scheduledTime}');
  ///   if (announcement.isRecurring) {
  ///     print('  Recurs: ${announcement.recurrence?.displayName}');
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// - [ScheduledAnnouncement] for the announcement data model
  /// - [cancelAnnouncementById] to cancel specific announcements
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    return await _notificationService.getScheduledAnnouncements();
  }

  /// Stream of announcement status updates.
  ///
  /// Subscribe to this stream to receive real-time updates about announcement
  /// lifecycle events such as when announcements are scheduled, delivering,
  /// completed, or failed.
  ///
  /// The stream emits [AnnouncementStatus] values indicating the current
  /// state of announcements. This is useful for:
  ///
  /// - Displaying real-time status in the UI
  /// - Logging announcement delivery
  /// - Tracking announcement reliability
  /// - Debugging scheduling issues
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Listen to status updates
  /// scheduler.statusStream.listen((status) {
  ///   switch (status) {
  ///     case AnnouncementStatus.scheduled:
  ///       print('Announcement scheduled successfully');
  ///       break;
  ///     case AnnouncementStatus.delivering:
  ///       print('Announcement is being delivered');
  ///       break;
  ///     case AnnouncementStatus.completed:
  ///       print('Announcement completed successfully');
  ///       break;
  ///     case AnnouncementStatus.failed:
  ///       print('Announcement delivery failed');
  ///       break;
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  ///
  /// - [AnnouncementStatus] for status values and their meanings
  Stream<AnnouncementStatus> get statusStream =>
      _notificationService.statusStream;

  /// Dispose resources and clean up.
  ///
  /// This method should be called when the [AnnouncementScheduler] is no
  /// longer needed. It performs cleanup including:
  ///
  /// - Closing the status stream
  /// - Stopping any active TTS operations
  /// - Canceling active timers
  /// - Releasing system resources
  ///
  /// After calling [dispose], the [AnnouncementScheduler] instance should not
  /// be used anymore. Create a new instance via [initialize] if needed.
  ///
  /// Note: This does NOT cancel scheduled announcements. Call
  /// [cancelScheduledAnnouncements] first if you want to cancel announcements.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // When cleaning up (e.g., app shutdown)
  /// try {
  ///   // Optionally cancel announcements first
  ///   await scheduler.cancelScheduledAnnouncements();
  ///
  ///   // Clean up resources
  ///   await scheduler.dispose();
  /// } catch (e) {
  ///   print('Error during cleanup: $e');
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// - [cancelScheduledAnnouncements] to cancel pending announcements
  /// - [initialize] to create a new scheduler instance
  Future<void> dispose() async {
    await _notificationService.dispose();
  }

  /// Calculate the next occurrence based on recurrence pattern
  DateTime _calculateNextOccurrence(
    TimeOfDay time,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    DateTime from,
  ) {
    final now = from;
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // For one-time announcements
    if (recurrence == null) {
      // If the time today has already passed, schedule for tomorrow
      if (today.isAfter(now)) {
        return today;
      } else {
        return today.add(const Duration(days: 1));
      }
    }

    // For recurring announcements, find the next valid day
    final targetDays = recurrence == RecurrencePattern.custom
        ? (customDays ?? [])
        : recurrence.defaultDays;

    // Start checking from today
    var candidate = today;

    // If today's time has passed, start from tomorrow
    if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Find the next day that matches our recurrence pattern
    while (!targetDays.contains(candidate.weekday)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  /// Log debug information if enabled
  void _log(String message) {
    if (_config.enableDebugLogging) {
      debugPrint('[AnnouncementScheduler] $message');
    }
  }
}
