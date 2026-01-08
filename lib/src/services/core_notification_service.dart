import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:notification_scheduler/src/models/notification_status.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/announcement_config.dart';
import '../models/announcement_exceptions.dart';
import '../models/recurrence_pattern.dart';
import '../models/scheduled_notification.dart';
import 'scheduling_settings_service.dart';

/// Core notification service for the announcement scheduler package.
///
/// This service handles the low-level notification scheduling, TTS configuration,
/// and announcement delivery without dependencies on specific app frameworks.
///
/// ## Android Platform Limitation
///
/// **Important**: Android's `PendingNotificationRequest` (from `flutter_local_notifications`)
/// does not expose the scheduled DateTime for pending notifications. The API only provides:
/// - Notification ID
/// - Title, body, payload
///
/// **Workaround**: This service persists scheduled times separately using
/// [SchedulingSettingsService] and reconciles them with platform notifications.
/// This enables accurate per-day validation and correct scheduled time retrieval.
class CoreNotificationService {
  static const String _defaultChannelId = 'scheduled_announcements';
  static const String _defaultChannelName = 'Scheduled Announcements';
  static const String _defaultChannelDescription =
      'Automated text-to-speech announcements';

  // Scheduling constants
  static const int _maxSchedulingDays = 14; // Android system limitation
  static const int _reconciliationLookaheadDays = 30; // Safe buffer > max days

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
  final StreamController<NotificationStatus> _statusController =
      StreamController<NotificationStatus>.broadcast();

  // Cleanup listener subscription
  StreamSubscription<NotificationStatus>? _cleanupSubscription;

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
  Stream<NotificationStatus> get statusStream => _statusController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Set timezone based on configuration
    if (_config.forceTimezone && _config.timezoneLocation != null) {
      tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
    }

    await _initializeTTS();

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
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    if (initialized != true) {
      throw NotificationInitializationException(
        'Failed to initialize notifications',
      );
    }

    // Request permissions for Android 13+
    await _requestPermissions();
    // Create notification channel for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannel();
    }
  }

  /// Schedule a one-time announcement
  Future<int> scheduleOneTimeAnnouncement({
    required String content,
    required DateTime dateTime,
    int? id,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _statusController.add(NotificationStatus.scheduled);

      tz.initializeTimeZones();
      if (_config.forceTimezone && _config.timezoneLocation != null) {
        tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
      }

      final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      // Use provided ID or generate one based on timestamp
      final announcementId = _generateId(id);

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Scheduling notification ID=$announcementId for $tzDateTime',
        );
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Current time: $now',
        );
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Time until notification: ${tzDateTime.difference(now).inSeconds} seconds',
        );
      }

      // Create the announcement object
      final announcement = ScheduledNotification(
        id: announcementId,
        content: content,
        scheduledTime: dateTime,
        isActive: true,
        metadata: metadata,
      );

      // Validate limits
      final existingAnnouncements = await getScheduledAnnouncements();
      await validateSchedulingLimits(announcement, existingAnnouncements);

      // Persist announcement
      await _settingsService.addScheduledAnnouncement(announcement);

      await _scheduleOneTimeNotification(
        notificationId: announcementId,
        scheduledDate: tzDateTime,
        content: content,
        title: 'Scheduled Announcement',
      );

      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] scheduleOneTimeAnnouncement: Stored scheduled time for notification ID=$announcementId',
        );
      }

      if (_config.enableTTS) {
        final delay = tzDateTime.difference(tz.TZDateTime.now(tz.local));
        _scheduleUnattendedAnnouncement(content, delay);
      }

      return announcementId;
    } catch (e) {
      _statusController.add(NotificationStatus.failed);
      debugPrint(
        '[CoreNotificationService] scheduleOneTimeAnnouncement: Error scheduling announcement: $e',
      );
      if (e is ValidationException) rethrow;
      throw NotificationSchedulingException(
        'Failed to schedule one-time announcement: $e',
      );
    }
  }

  int _generateId([int? id]) {
    if (id != null) return id % 2147483647;

    // Generate a unique ID that fits in a 32-bit integer (for Android notifications)
    // We use the last 9 digits of millisecondsSinceEpoch to ensure uniqueness within a reasonable timeframe
    // and keep it positive.
    return DateTime.now().millisecondsSinceEpoch % 2147483647;
  }

  /// Schedule a recurring announcement
  Future<int> scheduleRecurringAnnouncement({
    int? id,
    required String content,
    required TimeOfDay announcementTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    Map<String, dynamic>? metadata,
  }) async {
    final existingAnnouncements = await getScheduledAnnouncements();
    final announcementId = _generateId(id);

    await validateSchedulingLimits(
      ScheduledNotification(
        id: announcementId,
        content: content,
        scheduledTime: DateTime.now(), // Placeholder for validation
        isActive: true,
        recurrence: recurrence,
      ),
      existingAnnouncements,
    );

    try {
      _statusController.add(NotificationStatus.scheduled);

      // Store the announcement settings (keep for default time)
      await _settingsService.setAnnouncementTime(
        announcementTime.hour,
        announcementTime.minute,
      );

      // Create and persist the full announcement
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        announcementTime.hour,
        announcementTime.minute,
      );

      final announcement = ScheduledNotification(
        id: announcementId,
        content: content,
        scheduledTime: scheduledTime,
        recurrence: recurrence,
        customDays: customDays,
        isActive: true,
        metadata: metadata,
      );

      await _settingsService.addScheduledAnnouncement(announcement);

      if (recurrence != null) {
        await scheduleRecurringNotifications(
          announcementId: announcementId,
          content: content,
          recurrencePattern: recurrence,
          customDays: customDays ?? recurrence.defaultDays,
        );
      } else {
        await _scheduleOneTimeAtTimeOfDay(
          announcementId: announcementId,
          content: content,
        );
      }

      return announcementId;
    } catch (e) {
      _statusController.add(NotificationStatus.failed);
      throw NotificationSchedulingException(
        'Failed to schedule recurring announcement: $e',
      );
    }
  }

  /// Validate scheduling limits to prevent excessive notifications.
  ///
  /// **Platform Note**: Android does not enforce notification scheduling limits
  /// at the OS level, allowing apps to schedule unlimited notifications. However,
  /// excessive scheduling can lead to performance degradation, battery drain, and
  /// poor user experience.
  ///
  /// This validation is **highly recommended** to maintain app quality and prevent:
  /// - Notification fatigue (users disabling notifications or uninstalling)
  /// - Battery and memory impact from excessive pending notifications
  /// - System resource exhaustion
  /// - Degraded notification delivery reliability
  ///
  /// **Validation checks**:
  /// - Total scheduled notifications limit ([ValidationConfig.maxScheduledNotifications])
  /// - Per-day notification limit ([ValidationConfig.maxNotificationsPerDay])
  ///
  /// Throws [ValidationException] if limits would be exceeded.
  ///
  /// **Example**:
  /// ```dart
  /// // Configure reasonable limits
  /// final config = AnnouncementConfig(
  ///   validationConfig: ValidationConfig(
  ///     maxNotificationsPerDay: 5,
  ///     maxScheduledNotifications: 30,
  ///   ),
  /// );
  /// ```
  @visibleForTesting
  Future<void> validateSchedulingLimits(
    ScheduledNotification announcement,
    List<ScheduledNotification> existingAnnouncements,
  ) async {
    // Check total scheduled notifications limit
    final totalScheduled = existingAnnouncements.length;
    if (totalScheduled >= _config.validationConfig.maxScheduledNotifications) {
      throw ValidationException(
        'Cannot schedule announcement: maximum scheduled notifications limit '
        '(${_config.validationConfig.maxScheduledNotifications}) reached. '
        'Currently have $totalScheduled scheduled notifications.',
      );
    }

    // Check per-day limit
    final announcementDate = DateTime(
      announcement.scheduledTime.year,
      announcement.scheduledTime.month,
      announcement.scheduledTime.day,
    );

    // Count how many existing announcements are scheduled for the same day
    int sameDayCount = 0;
    for (final existing in existingAnnouncements) {
      final scheduledDate = DateTime(
        existing.scheduledTime.year,
        existing.scheduledTime.month,
        existing.scheduledTime.day,
      );
      if (scheduledDate == announcementDate) {
        sameDayCount++;
      }
    }

    // Add 1 for the new announcement being scheduled
    sameDayCount++;

    if (sameDayCount > _config.validationConfig.maxNotificationsPerDay) {
      throw ValidationException(
        'Cannot schedule announcement: maximum notifications per day limit '
        '(${_config.validationConfig.maxNotificationsPerDay}) would be exceeded. '
        'Would have $sameDayCount notifications for ${announcementDate.year}-${announcementDate.month.toString().padLeft(2, '0')}-${announcementDate.day.toString().padLeft(2, '0')}.',
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

      await _settingsService.setScheduledAnnouncements([]);
    } catch (e) {
      throw NotificationSchedulingException(
        'Failed to cancel notifications: $e',
      );
    }
  }

  /// Cancel a specific announcement by ID
  Future<void> cancelAnnouncementById(int id) async {
    try {
      await _notifications.cancel(id);
      await _settingsService.removeScheduledAnnouncement(id);
    } catch (e) {
      throw NotificationSchedulingException(
        'Failed to cancel announcement: $e',
      );
    }
  }

  /// Get list of scheduled announcements.
  ///
  /// **Platform Limitation**: Android's `PendingNotificationRequest` does not expose
  /// the scheduled DateTime. This method retrieves scheduled times from persistent
  /// storage ([SchedulingSettingsService]) where they are saved during scheduling.
  ///
  /// Returns a list of [ScheduledNotification] objects with accurate scheduled times.
  /// If a notification exists in the system but has no stored time (edge case),
  /// it defaults to the current time.
  Future<List<ScheduledNotification>> getScheduledAnnouncements() async {
    return _reconcileAnnouncements();
  }

  /// Reconcile stored announcements with platform notifications.
  ///
  /// This method performs the core logic of:
  /// 1. Retrieving stored announcements
  /// 2. Retrieving pending platform notifications
  /// 3. Filtering stored announcements to keep only those that are still pending
  /// 4. Cleaning up stale announcements from storage
  /// 5. Returning the list of active, sorted announcements
  Future<List<ScheduledNotification>> _reconcileAnnouncements() async {
    try {
      // Get stored definitions
      final storedAnnouncements = await _settingsService
          .getScheduledAnnouncements();

      // Get pending notifications to verify they are still active
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      final pendingIds = pendingNotifications.map((n) => n.id).toSet();

      final activeAnnouncements = <ScheduledNotification>[];
      final staleIds = <int>[];
      final matchedPendingIds = <int>{};

      for (final announcement in storedAnnouncements) {
        if (_isAnnouncementActive(
          announcement,
          pendingIds,
          matchedPendingIds,
        )) {
          activeAnnouncements.add(announcement);
        } else {
          staleIds.add(announcement.id);
        }
      }

      // Check for orphan notifications (exist in platform but no stored announcement)
      if (_config.enableDebugLogging) {
        final orphanIds = pendingIds.difference(matchedPendingIds);
        if (orphanIds.isNotEmpty) {
          debugPrint(
            '[CoreNotificationService] Found ${orphanIds.length} orphan notifications (no stored announcement): $orphanIds',
          );
        }
      }

      // Cleanup stale announcements
      if (staleIds.isNotEmpty) {
        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] Cleaning up stale announcements: $staleIds',
          );
        }
        await _settingsService.removeScheduledAnnouncements(staleIds);
      }

      // Sort by scheduled time (earliest first)
      activeAnnouncements.sort(
        (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
      );

      return activeAnnouncements;
    } catch (e) {
      throw NotificationSchedulingException(
        'Failed to get scheduled announcements: $e',
      );
    }
  }

  /// Check if an announcement is still active in pending notifications
  bool _isAnnouncementActive(
    ScheduledNotification announcement,
    Set<int> pendingIds,
    Set<int> matchedPendingIds,
  ) {
    bool isActive = false;
    final baseId = announcement.id;

    if (announcement.isOneTime) {
      // One-time: Check exact ID match
      if (pendingIds.contains(baseId)) {
        isActive = true;
        matchedPendingIds.add(baseId);
      }
    } else {
      // Recurring: Check if any notification derived from this ID exists
      // We check a reasonable range (e.g. base to base + 30)
      // Since we schedule up to 14 days ahead, 30 is safe.
      for (int i = 0; i < _reconciliationLookaheadDays; i++) {
        final idToCheck = baseId + i;
        if (pendingIds.contains(idToCheck)) {
          isActive = true;
          matchedPendingIds.add(idToCheck);
          // Continue checking to find all matches for orphan detection
        }
      }
    }
    return isActive;
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

      if (status == NotificationStatus.completed) {
        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] _setupCleanupListener: Status is completed, triggering cleanup',
          );
        }
        _cleanupCompletedAnnouncements();
      }
    });
  }

  /// Clean up completed announcements from storage.
  ///
  /// **Reconciliation Strategy**: Since Android's `PendingNotificationRequest` doesn't
  /// expose scheduled times, we maintain a separate persistence layer. This method
  /// reconciles stored scheduled times with actual pending notifications from the system.
  ///
  /// Platform notifications are the source of truth. Any notification IDs that exist
  /// in storage but are no longer pending (i.e., have been executed or canceled)
  /// are removed from storage to prevent stale data.
  Future<void> _cleanupCompletedAnnouncements() async {
    try {
      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] _cleanupCompletedAnnouncements: Triggering reconciliation',
        );
      }

      // Reconcile storage with platform notifications
      // This removes any stale announcements (those not in pending notifications).
      await _reconcileAnnouncements();
    } catch (e) {
      if (_config.enableDebugLogging) {
        debugPrint('[CoreNotificationService] Cleanup failed: $e');
      }
    }
  }

  /// Initialize TTS with configuration
  Future<void> _initializeTTS() async {
    if (!_config.enableTTS) return;

    try {
      _tts = FlutterTts();
      if (_tts != null) {
        await _tts!.setLanguage(_config.ttsLanguage ?? 'en-US');
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

  /// Schedule a one-time notification at the configured time (next occurrence)
  Future<void> _scheduleOneTimeAtTimeOfDay({
    required int announcementId,
    required String content,
  }) async {
    final hour = await _settingsService.getAnnouncementHour();
    final minute = await _settingsService.getAnnouncementMinute();

    if (hour == null || minute == null) {
      throw NotificationSchedulingException('Announcement time not set');
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

    await _scheduleOneTimeNotification(
      notificationId: announcementId,
      scheduledDate: scheduledDate,
      content: content,
      title: 'Scheduled Announcement',
    );

    if (_config.enableTTS) {
      final announcementDelay = scheduledDate.difference(now);
      _scheduleUnattendedAnnouncement(content, announcementDelay);
    }
  }

  /// Schedule recurring notifications
  @visibleForTesting
  Future<void> scheduleRecurringNotifications({
    required int announcementId,
    required String content,
    required RecurrencePattern recurrencePattern,
    required List<int> customDays,
  }) async {
    final hour = await _settingsService.getAnnouncementHour();
    final minute = await _settingsService.getAnnouncementMinute();

    if (hour == null || minute == null) {
      throw NotificationSchedulingException('Announcement time not set');
    }

    // Validate recurring settings
    await _validateRecurringSettings(recurrencePattern, customDays);

    tz.initializeTimeZones();
    if (_config.forceTimezone && _config.timezoneLocation != null) {
      tz.setLocalLocation(tz.getLocation(_config.timezoneLocation!));
    }

    final now = tz.TZDateTime.now(tz.local);

    // Create the base scheduled time using the configured hour and minute
    final baseScheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final result = _calculateRecurringDatesAndComponent(
      recurrencePattern: recurrencePattern,
      baseScheduledTime: baseScheduledTime,
      now: now,
      customDays: customDays,
      getRecurringDates: _getRecurringDates,
    );

    await _scheduleNotifications(
      datesToSchedule: result.dates,
      matchComponent: result.component,
      announcementId: announcementId,
      content: content,
      config: _config,
      now: now,
      scheduleRecurringNotification: _scheduleRecurringNotification,
      scheduleUnattendedAnnouncement: _scheduleUnattendedAnnouncement,
    );
  }

  static ({List<tz.TZDateTime> dates, DateTimeComponents component})
  _calculateRecurringDatesAndComponent({
    required RecurrencePattern recurrencePattern,
    required tz.TZDateTime baseScheduledTime,
    required tz.TZDateTime now,
    required List<int> customDays,
    required List<tz.TZDateTime> Function({
      required RecurrencePattern recurrencePattern,
      required List<int> customDays,
      required tz.TZDateTime startDate,
      required int maxDays,
    })
    getRecurringDates,
  }) {
    if (recurrencePattern == RecurrencePattern.daily) {
      // For daily, we just need the next occurrence
      var scheduledDate = baseScheduledTime;
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      return (dates: [scheduledDate], component: DateTimeComponents.time);
    } else {
      // For other patterns, we need to find the next occurrence of each target day
      // We check the next 14 days to ensure we find all unique weekdays involved,
      // even if today's time has passed.
      final potentialDates = getRecurringDates(
        recurrencePattern: recurrencePattern,
        customDays: customDays,
        startDate: baseScheduledTime,
        maxDays: _maxSchedulingDays,
      );

      // Filter to keep only the first occurrence of each weekday
      final dates = <tz.TZDateTime>[];
      final seenWeekdays = <int>{};
      for (final date in potentialDates) {
        if (!seenWeekdays.contains(date.weekday)) {
          dates.add(date);
          seenWeekdays.add(date.weekday);
        }
      }
      return (dates: dates, component: DateTimeComponents.dayOfWeekAndTime);
    }
  }

  static Future<void> _scheduleNotifications({
    required List<tz.TZDateTime> datesToSchedule,
    required DateTimeComponents matchComponent,
    required int announcementId,
    required String content,
    required AnnouncementConfig config,
    required tz.TZDateTime now,
    required Future<void> Function({
      required int notificationId,
      required tz.TZDateTime scheduledDate,
      required String content,
      required String title,
      DateTimeComponents? matchDateTimeComponents,
    })
    scheduleRecurringNotification,
    required void Function(String, Duration) scheduleUnattendedAnnouncement,
  }) async {
    for (int i = 0; i < datesToSchedule.length; i++) {
      final scheduledDate = datesToSchedule[i];
      final notificationId = announcementId + i;
      await scheduleRecurringNotification(
        notificationId: notificationId,
        scheduledDate: scheduledDate,
        content: content,
        title: 'Recurring Announcement',
        matchDateTimeComponents: matchComponent,
      );

      if (config.enableTTS && i == 0) {
        // Only schedule TTS for the next occurrence (closest one)
        final announcementDelay = scheduledDate.difference(now);
        scheduleUnattendedAnnouncement(content, announcementDelay);
      }
    }
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
    DateTimeComponents? matchDateTimeComponents,
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
        '[CoreNotificationService] _scheduleRecurringNotification: Using schedule mode=$scheduleMode, matchDateTimeComponents=$matchDateTimeComponents',
      );
    }

    await _notifications.zonedSchedule(
      notificationId,
      title,
      content,
      scheduledDate,
      platformDetails,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents:
          matchDateTimeComponents ?? DateTimeComponents.time,
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
        _statusController.add(NotificationStatus.delivering);
        await _tts!.speak(content);
      } catch (e) {
        _statusController.add(NotificationStatus.failed);
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
            throw ValidationException(
              'Custom recurrence pattern requires at least one day to be selected',
            );
          }
          if (customDays.length > 7) {
            throw ValidationException(
              'Custom recurrence pattern cannot have more than 7 days',
            );
          }
          break;
        case RecurrencePattern.daily:
          // Daily is always valid, but check against max notifications
          if (_config.validationConfig.maxNotificationsPerDay < 1) {
            throw ValidationException(
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
      if (dayOffset == 0 && !scheduledDateTime.isAfter(startDate)) {
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
  void onNotificationResponse(NotificationResponse response) {
    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] onNotificationResponse: Received notification response - ID=${response.id}, payload=${response.payload}, actionId=${response.actionId}',
      );
    }

    // Emit completed status to trigger cleanup via listener
    _statusController.add(NotificationStatus.completed);

    if (_config.enableDebugLogging) {
      debugPrint(
        '[CoreNotificationService] onNotificationResponse: Emitted AnnouncementStatus.completed to status stream',
      );
    }

    if (_config.enableTTS && _tts != null) {
      // Trigger TTS for notification content
      final payload = response.payload ?? response.actionId ?? '';
      if (payload.isNotEmpty) {
        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] onNotificationResponse: Triggering TTS for payload: $payload',
          );
        }
        _tts!.speak(payload);
      } else {
        if (_config.enableDebugLogging) {
          debugPrint(
            '[CoreNotificationService] onNotificationResponse: No payload to speak (empty)',
          );
        }
      }
    } else {
      if (_config.enableDebugLogging) {
        debugPrint(
          '[CoreNotificationService] onNotificationResponse: TTS not triggered (enableTTS=${_config.enableTTS}, tts=$_tts)',
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
