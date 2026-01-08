import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models/announcement_config.dart';
import 'models/announcement_exceptions.dart';
import 'models/notification_status.dart';
import 'models/recurrence_pattern.dart';
import 'models/scheduled_notification.dart';
import 'services/core_notification_service.dart';
import 'services/hive_storage_service.dart';
import 'services/scheduling_settings_service.dart';

/// Main entry point for the announcement scheduler package.
///
/// [NotificationScheduler] provides a clean API for scheduling both one-time
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
/// final scheduler = await AnnouncementScheduler.create(
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
/// - [ScheduledNotification] for announcement data model
/// - [NotificationStatus] for announcement lifecycle states
class NotificationScheduler {
  final AnnouncementConfig _config;
  final CoreNotificationService? _notificationService;
  DateTime Function(
    TimeOfDay time,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    DateTime from,
  )
  _calculateNextOccurrence;

  NotificationScheduler._({
    required AnnouncementConfig config,
    CoreNotificationService? notificationService,
    DateTime Function(
      TimeOfDay time,
      RecurrencePattern? recurrence,
      List<int>? customDays,
      DateTime from,
    )?
    calculateNextOccurrence,
  }) : _config = config,
       _notificationService = notificationService,
       _calculateNextOccurrence =
           calculateNextOccurrence ?? _calculateNextOccurrenceFn;

  /// Initialize the announcement scheduler with the given configuration.
  ///
  /// This is the primary factory method for creating an [NotificationScheduler]
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
  /// - [notificationService]: Optional notification service for dependency
  ///   injection. If not provided, a default service will be created and
  ///   initialized. Use this parameter for testing purposes to inject a mock
  ///   service.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a fully initialized [NotificationScheduler]
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
  static Future<NotificationScheduler> create({
    required AnnouncementConfig config,
    CoreNotificationService? notificationService,
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

    // Use provided notification service or create default
    final CoreNotificationService service;
    if (notificationService != null) {
      service = notificationService;
    } else {
      // Initialize storage service
      final storageService = await HiveStorageService.create();

      // Initialize settings service
      final settingsService = SchedulingSettingsService(storageService);

      // Initialize core notification service
      service = CoreNotificationService(
        settingsService: settingsService,
        config: config,
      );
      await service.initialize();
    }

    return NotificationScheduler._(
      config: config,
      notificationService: service,
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
  /// - [id]: Optional unique identifier. If not provided, one will be generated.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with the ID of the scheduled announcement.
  /// Use [getScheduledAnnouncements] to view all scheduled announcements.
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
  /// - [getScheduledAnnouncements] to view all scheduled announcements
  /// - [cancelScheduledAnnouncements] to cancel all announcements
  /// - [RecurrencePattern] for available recurrence options
  Future<int> scheduleAnnouncement({
    required String content,
    required TimeOfDay announcementTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    Map<String, dynamic>? metadata,
    DateTime? currentTime,
    int? id,
  }) async {
    currentTime ??= DateTime.now();
    // Validate content
    if (content.trim().isEmpty) {
      throw ValidationException('Announcement content cannot be empty');
    }

    // Validate custom days if using custom recurrence
    if (recurrence == RecurrencePattern.custom) {
      if (customDays == null || customDays.isEmpty) {
        throw ValidationException(
          'Custom days must be provided when using custom recurrence pattern',
        );
      }
      if (customDays.any((day) => day < 1 || day > 7)) {
        throw ValidationException(
          'Custom days must be between 1 (Monday) and 7 (Sunday)',
        );
      }
    }

    // Calculate next occurrence for logging
    final nextOccurrence = _calculateNextOccurrence(
      announcementTime,
      recurrence,
      customDays,
      currentTime,
    );

    // Schedule with the notification service
    final announcementId = await _notificationService!
        .scheduleRecurringAnnouncement(
          id: id,
          content: content,
          announcementTime: announcementTime,
          recurrence: recurrence,
          customDays: customDays,
          metadata: metadata,
        );

    _log('Scheduled announcement at $nextOccurrence with ID: $announcementId');

    return announcementId;
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
  /// - [id]: Optional unique identifier. If not provided, one will be generated.
  ///   Must be a numeric string if provided.
  ///
  /// - [metadata]: Optional custom data to associate with the announcement.
  ///   This can be used to store additional context or application-specific
  ///   information.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with the ID of the scheduled announcement.
  /// Use [getScheduledAnnouncements] to view all scheduled announcements.
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
  ///   id: 123456789,
  ///   metadata: {'type': 'birthday', 'person': 'John'},
  /// );
  /// ```
  ///
  /// See also:
  ///
  /// - [scheduleAnnouncement] for recurring or time-based announcements
  /// - [getScheduledAnnouncements] to view all scheduled announcements
  /// - [cancelScheduledAnnouncements] to cancel all announcements
  Future<int> scheduleOneTimeAnnouncement({
    required String content,
    required DateTime dateTime,
    int? id,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate content
    if (content.trim().isEmpty) {
      throw ValidationException('Announcement content cannot be empty');
    }

    // Validate date is in the future
    if (dateTime.isBefore(DateTime.now())) {
      throw ValidationException('Scheduled time must be in the future');
    }

    // Generate ID if not provided
    final announcementId = id ?? DateTime.now().millisecondsSinceEpoch;

    // Schedule with the notification service
    await _notificationService!.scheduleOneTimeAnnouncement(
      content: content,
      dateTime: dateTime,
      id: announcementId,
      metadata: metadata,
    );

    if (_config.enableDebugLogging) {
      _log(
        'Scheduled one-time announcement at $dateTime with ID: $announcementId',
      );
    }

    return announcementId;
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
    await _notificationService!.cancelAllNotifications();
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
  Future<void> cancelAnnouncementById(int id) async {
    await _notificationService!.cancelAnnouncementById(id);
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
  /// A [Future] that completes with a list of [ScheduledNotification] objects
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
  /// - [ScheduledNotification] for the announcement data model
  /// - [cancelAnnouncementById] to cancel specific announcements
  Future<List<ScheduledNotification>> getScheduledAnnouncements() async {
    return await _notificationService!.getScheduledAnnouncements();
  }

  /// Stream of announcement status updates.
  ///
  /// Subscribe to this stream to receive real-time updates about announcement
  /// lifecycle events such as when announcements are scheduled, delivering,
  /// completed, or failed.
  ///
  /// The stream emits [NotificationStatus] values indicating the current
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
  /// - [NotificationStatus] for status values and their meanings
  Stream<NotificationStatus> get statusStream =>
      _notificationService!.statusStream;

  /// Dispose resources and clean up.
  ///
  /// This method should be called when the [NotificationScheduler] is no
  /// longer needed. It performs cleanup including:
  ///
  /// - Closing the status stream
  /// - Stopping any active TTS operations
  /// - Canceling active timers
  /// - Releasing system resources
  ///
  /// After calling [dispose], the [NotificationScheduler] instance should not
  /// be used anymore. Create a new instance via [create] if needed.
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
  /// - [create] to create a new scheduler instance
  Future<void> dispose() async {
    await _notificationService!.dispose();
  }

  /// Calculate the next occurrence based on recurrence pattern
  static DateTime _calculateNextOccurrenceFn(
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

  /// This setter allows overriding the calculation function for testing
  /// purposes. In production, the default implementation is used.
  @visibleForTesting
  set calculateNextOccurrence(
    DateTime Function(
      TimeOfDay time,
      RecurrencePattern? recurrence,
      List<int>? customDays,
      DateTime from,
    )
    fn,
  ) {
    _calculateNextOccurrence = fn;
  }
}
