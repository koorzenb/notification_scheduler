import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/announcement_config.dart';
import '../models/announcement_exceptions.dart';
import '../models/announcement_status.dart';
import '../models/recurrence_pattern.dart';
import '../models/scheduled_announcement.dart';
import 'scheduling_settings_service.dart';

/// Core notification service for the announcement scheduler package.
///
/// This service handles the low-level notification scheduling, TTS configuration,
/// and announcement delivery without dependencies on specific app frameworks.
class CoreNotificationService {
  static const String _defaultChannelId = 'scheduled_announcements';
  static const String _defaultChannelName = 'Scheduled Announcements';
  static const String _defaultChannelDescription =
      'Automated text-to-speech announcements';

  // Validation constants to prevent excessive notification load (used by validation config)

  final FlutterLocalNotificationsPlugin _notifications;
  FlutterTts? _tts;
  final SchedulingSettingsService _settingsService;
  final AnnouncementConfig _config;
  bool _exactAlarmsAllowed = false;
  bool _notificationAllowed = false;

  // Track active timers for unattended announcements
  final List<Timer> _activeAnnouncementTimers = [];

  // Stream controller for status updates
  final StreamController<AnnouncementStatus> _statusController =
      StreamController<AnnouncementStatus>.broadcast();

  // Cleanup listener subscription
  StreamSubscription<AnnouncementStatus>? _cleanupSubscription;

  CoreNotificationService({
    required SchedulingSettingsService settingsService,
    required AnnouncementConfig config,
    FlutterLocalNotificationsPlugin? notifications,
    FlutterTts? tts,
  }) : _settingsService = settingsService,
       _config = config,
       _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _tts = tts {
    // Set up cleanup listener for completed announcements
    _setupCleanupListener();
  }

  /// Get whether both notification permissions and exact alarms are allowed
  bool get isNotificationsAllowed =>
      _exactAlarmsAllowed && _notificationAllowed;

  /// Stream of announcement status updates
  Stream<AnnouncementStatus> get statusStream => _statusController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Set timezone based on configuration
    if (_config.forceTimezone && _config.timezoneLocation != null) {
      tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
    }

    await _initializeTts();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) =>
          onNotificationResponse(response, _statusController, _config, _tts),
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    if (initialized != true) {
      throw const NotificationInitializationException(
        'Failed to initialize notifications',
      );
    }

    // Request permissions for Android 13+
    await _requestPermissions();

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Schedule a one-time announcement
  Future<void> scheduleOneTimeAnnouncement({
    required String content,
    required DateTime dateTime,
  }) async {
    try {
      _statusController.add(AnnouncementStatus.scheduled);

      tz.initializeTimeZones();
      if (_config.forceTimezone && _config.timezoneLocation != null) {
        tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
      }

      final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Scheduling notification ID=$notificationId for $tzDateTime',
        );
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Current time: $now',
        );
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Time until notification: ${tzDateTime.difference(now).inSeconds} seconds',
        );
      }

      await _scheduleOneTimeNotification(
        notificationId: notificationId,
        scheduledDate: tzDateTime,
        content: content,
        title: 'Scheduled Announcement',
      );

      // Store the scheduled time for later retrieval
      await _settingsService.setScheduledTime(notificationId, tzDateTime);

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Stored scheduled time for notification ID=$notificationId',
        );
      }

      if (_config.enableTTS) {
        final delay = tzDateTime.difference(tz.TZDateTime.now(tz.local));
        _scheduleUnattendedAnnouncement(content, delay);
      }
    } catch (e) {
      _statusController.add(AnnouncementStatus.failed);
      throw NotificationSchedulingException(
        'Failed to schedule one-time announcement: $e',
      );
    }
  }

  /// Schedule a recurring announcement
  Future<void> scheduleRecurringAnnouncement({
    required String content,
    required TimeOfDay announcementTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
  }) async {
    try {
      _statusController.add(AnnouncementStatus.scheduled);

      // Store the announcement settings
      await _settingsService.setAnnouncementTime(
        announcementTime.hour,
        announcementTime.minute,
      );

      if (recurrence != null) {
        await _settingsService.setIsRecurring(true);
        await _settingsService.setRecurrencePattern(recurrence);
        if (customDays != null) {
          await _settingsService.setRecurrenceDays(customDays);
        }

        await _scheduleRecurringNotifications(
          content: content,
          recurrencePattern: recurrence,
          customDays: customDays ?? recurrence.defaultDays,
        );
      } else {
        await _settingsService.setIsRecurring(false);
        await _scheduleDailyNotification(content: content);
      }
    } catch (e) {
      _statusController.add(AnnouncementStatus.failed);
      throw NotificationSchedulingException(
        'Failed to schedule recurring announcement: $e',
      );
    }
  }

  /// Cancel all scheduled announcements
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();

      // Cancel all active timers
      for (final timer in _activeAnnouncementTimers) {
        timer.cancel();
      }
      _activeAnnouncementTimers.clear();

      // Clear stored scheduled times
      await _settingsService.clearScheduledTimes();
    } catch (e) {
      throw NotificationSchedulingException(
        'Failed to cancel notifications: $e',
      );
    }
  }

  /// Cancel a specific announcement by ID
  Future<void> cancelAnnouncementById(String id) async {
    try {
      final notificationId = int.tryParse(id);
      if (notificationId != null) {
        await _notifications.cancel(notificationId);
      }
    } catch (e) {
      throw NotificationSchedulingException(
        'Failed to cancel announcement: $e',
      );
    }
  }

  /// Get list of scheduled announcements
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    try {
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();

      // Retrieve stored scheduled times
      // flutter_local_notifications doesn't expose scheduled times in its API,
      // so we persist them separately when scheduling and retrieve them here
      final scheduledTimes = await _settingsService.getScheduledTimes();

      return pendingNotifications.map((notification) {
        final storedTime = scheduledTimes[notification.id.toString()];
        final scheduledTime = storedTime != null
            ? DateTime.fromMillisecondsSinceEpoch(storedTime)
            : DateTime.now();

        return ScheduledAnnouncement(
          id: notification.id.toString(),
          content: notification.body ?? '',
          scheduledTime: scheduledTime,
          isActive: true,
        );
      }).toList();
    } catch (e) {
      throw NotificationSchedulingException(
        'Failed to get scheduled announcements: $e',
      );
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    // Cancel cleanup subscription
    await _cleanupSubscription?.cancel();
    _cleanupSubscription = null;

    // Cancel all active timers
    for (final timer in _activeAnnouncementTimers) {
      timer.cancel();
    }
    _activeAnnouncementTimers.clear();

    // Dispose TTS
    await _tts?.stop();

    // Close status stream
    await _statusController.close();

    // Dispose settings service
    await _settingsService.dispose();
  }

  /// Set up listener for cleaning up completed announcements
  void _setupCleanupListener() {
    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _setupCleanupListener: Setting up cleanup listener for status stream',
      );
    }

    _cleanupSubscription = _statusController.stream.listen((status) {
      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] _setupCleanupListener: Received status update: $status',
        );
      }

      if (status == AnnouncementStatus.completed) {
        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] _setupCleanupListener: Status is completed, triggering cleanup',
          );
        }
        _cleanupCompletedAnnouncements();
      }
    });
  }

  /// Clean up completed announcements from storage
  ///
  /// This method reconciles the stored scheduled times with actual pending
  /// notifications. Any notification IDs that exist in storage but are no
  /// longer pending (i.e., have been executed) are removed from storage.
  Future<void> _cleanupCompletedAnnouncements() async {
    try {
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      final pendingIds = pendingNotifications
          .map((n) => n.id.toString())
          .toSet();

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] _cleanupCompletedAnnouncements: Pending notification IDs from system: $pendingIds',
        );
        debugPrint(
          '[CoreNotificationService] _cleanupCompletedAnnouncements: Number of pending: ${pendingIds.length}',
        );
      }

      final storedTimes = await _settingsService.getScheduledTimes();

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] _cleanupCompletedAnnouncements: Stored times keys: ${storedTimes.keys.toList()}',
        );
        debugPrint(
          '[CoreNotificationService] _cleanupCompletedAnnouncements: Stored times: $storedTimes',
        );
      }

      final idsToRemove = storedTimes.keys
          .where((id) => !pendingIds.contains(id))
          .toList();

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] _cleanupCompletedAnnouncements: IDs to remove: $idsToRemove',
        );
      }

      if (idsToRemove.isNotEmpty) {
        // Remove completed announcements from storage
        for (final id in idsToRemove) {
          storedTimes.remove(id);
        }

        // Convert back to Map<int, DateTime> for storage
        final cleanedTimes = <int, DateTime>{};
        for (final entry in storedTimes.entries) {
          final intKey = int.tryParse(entry.key);
          if (intKey != null) {
            cleanedTimes[intKey] = DateTime.fromMillisecondsSinceEpoch(
              entry.value,
            );
          }
        }

        await _settingsService.setScheduledTimes(cleanedTimes);

        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] Cleaned up ${idsToRemove.length} completed announcement(s)',
          );
        }
      } else {
        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] No announcements to clean up (all still pending)',
          );
        }
      }
    } catch (e) {
      if (_config.enableDebugLogging) {
        debugPrint('[CoreNotificationService] Cleanup failed: $e');
      }
    }
  }

  /// Initialize TTS with configuration
  Future<void> _initializeTts() async {
    if (!_config.enableTTS) return;

    try {
      _tts = FlutterTts();
      if (_tts != null) {
        await _tts!.setSpeechRate(_config.ttsRate);
        await _tts!.setPitch(_config.ttsPitch);
        await _tts!.setVolume(_config.ttsVolume);
      }
    } catch (e) {
      // TTS initialization failed, but continue without it
      _tts = null;
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    // Request notification permission for Android 13+
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      _notificationAllowed =
          await androidPlugin.requestNotificationsPermission() ?? false;

      _exactAlarmsAllowed =
          await androidPlugin.requestExactAlarmsPermission() ?? false;
    }
  }

  /// Create notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: _defaultChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  /// Schedule a daily recurring notification at a specific time
  Future<void> _scheduleDailyNotification({required String content}) async {
    final hour = await _settingsService.getAnnouncementHour();
    final minute = await _settingsService.getAnnouncementMinute();

    if (hour == null || minute == null) {
      throw const NotificationSchedulingException('Announcement time not set');
    }

    tz.initializeTimeZones();
    if (_config.forceTimezone && _config.timezoneLocation != null) {
      tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleRecurringNotification(
      notificationId: 0,
      scheduledDate: scheduledDate,
      content: content,
      title: 'Scheduled Announcement',
    );

    // Store the scheduled time for later retrieval
    await _settingsService.setScheduledTime(0, scheduledDate);

    if (_config.enableTTS) {
      final announcementDelay = scheduledDate.difference(now);
      _scheduleUnattendedAnnouncement(content, announcementDelay);
    }
  }

  /// Schedule recurring notifications
  Future<void> _scheduleRecurringNotifications({
    required String content,
    required RecurrencePattern recurrencePattern,
    required List<int> customDays,
  }) async {
    final hour = await _settingsService.getAnnouncementHour();
    final minute = await _settingsService.getAnnouncementMinute();

    if (hour == null || minute == null) {
      throw const NotificationSchedulingException('Announcement time not set');
    }

    // Validate recurring settings
    await _validateRecurringSettings(recurrencePattern, customDays);

    tz.initializeTimeZones();
    if (_config.forceTimezone && _config.timezoneLocation != null) {
      tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
    }

    final now = tz.TZDateTime.now(tz.local);
    final daysToSchedule = _getRecurringDates(
      recurrencePattern: recurrencePattern,
      customDays: customDays,
      startDate: now,
      maxDays: 14, // Android system limitation
    );

    // Build map of notification IDs to scheduled times for batch storage
    final scheduledTimesMap = <int, DateTime>{};

    for (int i = 0; i < daysToSchedule.length; i++) {
      final scheduledDate = daysToSchedule[i];
      await _scheduleRecurringNotification(
        notificationId: i,
        scheduledDate: scheduledDate,
        content: content,
        title: 'Recurring Announcement',
      );

      // Store scheduled time for later retrieval
      scheduledTimesMap[i] = scheduledDate;

      if (_config.enableTTS && i == 0) {
        // Only schedule TTS for the next occurrence
        final announcementDelay = scheduledDate.difference(now);
        _scheduleUnattendedAnnouncement(content, announcementDelay);
      }
    }

    await _settingsService.setScheduledTimes(scheduledTimesMap);
  }

  /// Schedule a one-time notification (no recurrence)
  Future<void> _scheduleOneTimeNotification({
    required int notificationId,
    required tz.TZDateTime scheduledDate,
    required String content,
    required String title,
  }) async {
    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _scheduleOneTimeNotification: Attempting to schedule ID=$notificationId for $scheduledDate',
      );
      debugPrint(
        '[CoreNotificationService] _scheduleOneTimeNotification: exactAlarmsAllowed=$_exactAlarmsAllowed, notificationAllowed=$_notificationAllowed',
      );
    }

    final androidDetails = AndroidNotificationDetails(
      _config.notificationConfig.channelId,
      _config.notificationConfig.channelName,
      channelDescription: _config.notificationConfig.channelDescription,
      importance: _config.notificationConfig.importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduleMode = _exactAlarmsAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _scheduleOneTimeNotification: Using schedule mode=$scheduleMode (NO matchDateTimeComponents for one-time notification)',
      );
    }

    // For one-time notifications, DO NOT use matchDateTimeComponents
    // This ensures the notification fires exactly once at the specified date/time
    await _notifications.zonedSchedule(
      notificationId,
      title,
      content,
      scheduledDate,
      platformDetails,
      androidScheduleMode: scheduleMode,
      payload: content, // Add payload so notification response can trigger TTS
    );

    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _scheduleOneTimeNotification: Successfully called zonedSchedule for ID=$notificationId',
      );

      // Verify it was actually scheduled
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      final wasScheduled = pendingNotifications.any(
        (n) => n.id == notificationId,
      );
      debugPrint(
        '[CoreNotificationService] _scheduleOneTimeNotification: Verification - notification in pending list: $wasScheduled',
      );
      if (wasScheduled) {
        final notification = pendingNotifications.firstWhere(
          (n) => n.id == notificationId,
        );
        debugPrint(
          '[CoreNotificationService] _scheduleOneTimeNotification: Pending notification - title: ${notification.title}, body: ${notification.body}',
        );
      }
    }
  }

  /// Schedule a recurring notification (with matchDateTimeComponents)
  Future<void> _scheduleRecurringNotification({
    required int notificationId,
    required tz.TZDateTime scheduledDate,
    required String content,
    required String title,
  }) async {
    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _scheduleRecurringNotification: Attempting to schedule ID=$notificationId for $scheduledDate',
      );
      debugPrint(
        '[CoreNotificationService] _scheduleRecurringNotification: exactAlarmsAllowed=$_exactAlarmsAllowed, notificationAllowed=$_notificationAllowed',
      );
    }

    final androidDetails = AndroidNotificationDetails(
      _config.notificationConfig.channelId,
      _config.notificationConfig.channelName,
      channelDescription: _config.notificationConfig.channelDescription,
      importance: _config.notificationConfig.importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduleMode = _exactAlarmsAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _scheduleRecurringNotification: Using schedule mode=$scheduleMode, matchDateTimeComponents=DateTimeComponents.time',
      );
    }

    await _notifications.zonedSchedule(
      notificationId,
      title,
      content,
      scheduledDate,
      platformDetails,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: content, // Add payload for notification response
    );

    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] _scheduleRecurringNotification: Successfully called zonedSchedule for ID=$notificationId',
      );
    }
  }

  /// Schedule unattended TTS announcement
  void _scheduleUnattendedAnnouncement(String content, Duration delay) {
    if (!_config.enableTTS || _tts == null) return;

    final timer = Timer(delay, () async {
      try {
        _statusController.add(AnnouncementStatus.delivering);
        await _tts!.speak(content);
      } catch (e) {
        _statusController.add(AnnouncementStatus.failed);
      }
    });

    _activeAnnouncementTimers.add(timer);
  }

  /// Validate recurring settings to prevent excessive notifications
  Future<void> _validateRecurringSettings(
    RecurrencePattern pattern,
    List<int> customDays,
  ) async {
    if (_config.validationConfig.enableEdgeCaseValidation) {
      // Validate pattern-specific constraints
      switch (pattern) {
        case RecurrencePattern.custom:
          if (customDays.isEmpty) {
            throw const ValidationException(
              'Custom recurrence pattern requires at least one day to be selected',
            );
          }
          if (customDays.length > 7) {
            throw const ValidationException(
              'Custom recurrence pattern cannot have more than 7 days',
            );
          }
          break;
        case RecurrencePattern.daily:
          // Daily is always valid, but check against max notifications
          if (_config.validationConfig.maxNotificationsPerDay < 1) {
            throw const ValidationException(
              'Daily notifications require at least 1 notification per day',
            );
          }
          break;
        default:
          // Other patterns are generally safe
          break;
      }
    }
  }

  /// Get list of dates for recurring notifications
  List<tz.TZDateTime> _getRecurringDates({
    required RecurrencePattern recurrencePattern,
    required List<int> customDays,
    required tz.TZDateTime startDate,
    required int maxDays,
  }) {
    final List<tz.TZDateTime> dates = [];
    final hour = startDate.hour;
    final minute = startDate.minute;

    for (int dayOffset = 0; dayOffset < maxDays; dayOffset++) {
      final candidateDate = startDate.add(Duration(days: dayOffset));
      final scheduledDateTime = tz.TZDateTime(
        tz.local,
        candidateDate.year,
        candidateDate.month,
        candidateDate.day,
        hour,
        minute,
      );

      // Skip if the time has already passed today
      if (dayOffset == 0 && scheduledDateTime.isBefore(startDate)) {
        continue;
      }

      // Check if this day matches the recurrence pattern
      final dayOfWeek = candidateDate.weekday; // 1=Monday, 7=Sunday
      final List<int> targetDays;

      switch (recurrencePattern) {
        case RecurrencePattern.daily:
          targetDays = [1, 2, 3, 4, 5, 6, 7];
          break;
        case RecurrencePattern.weekdays:
          targetDays = [1, 2, 3, 4, 5];
          break;
        case RecurrencePattern.weekends:
          targetDays = [6, 7];
          break;
        case RecurrencePattern.custom:
          targetDays = customDays;
          break;
      }

      if (targetDays.contains(dayOfWeek)) {
        dates.add(scheduledDateTime);
      }
    }

    return dates;
  }

  /// Handle notification response
  ///
  /// This method is made testable by accepting dependencies as parameters.
  /// This allows for easier unit testing without requiring a full service instance.
  @visibleForTesting
  void onNotificationResponse(
    NotificationResponse response,
    StreamController<AnnouncementStatus> statusController,
    AnnouncementConfig config,
    FlutterTts? tts,
  ) {
    if (config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] onNotificationResponse: Received notification response - ID=${response.id}, payload=${response.payload}, actionId=${response.actionId}',
      );
    }

    // Emit completed status to trigger cleanup via listener
    statusController.add(AnnouncementStatus.completed);

    if (config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] onNotificationResponse: Emitted AnnouncementStatus.completed to status stream',
      );
    }

    if (config.enableTTS && tts != null) {
      // Trigger TTS for notification content
      final payload = response.payload ?? response.actionId ?? '';
      if (payload.isNotEmpty) {
        if (config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] onNotificationResponse: Triggering TTS for payload: $payload',
          );
        }
        tts.speak(payload);
      } else {
        if (config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] onNotificationResponse: No payload to speak (empty)',
          );
        }
      }
    } else {
      if (config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] onNotificationResponse: TTS not triggered (enableTTS=${config.enableTTS}, tts=$tts)',
        );
      }
    }
  }

  /// Handle background notification response
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Background processing if needed
    // Note: Cannot emit status or trigger cleanup here as this is a static method
    // Cleanup will happen on next app launch when pending notifications are reconciled
  }
}
