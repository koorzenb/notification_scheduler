import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/announcement_config.dart';
import '../models/announcement_exceptions.dart';
import '../models/scheduled_announcement.dart';

/// Core service for managing announcements and notifications
class AnnouncementService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  FlutterTts? _tts;
  AnnouncementConfig? _config;

  // Track active timers for unattended announcements
  final List<Timer> _activeAnnouncementTimers = [];

  /// Initialize the service with the given configuration
  Future<void> initialize(AnnouncementConfig config) async {
    _config = config;

    await _initializeNotifications();

    if (config.enableTTS) {
      await _initializeTTS();
    }
  }

  /// Initialize the notifications plugin
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
    );

    final initialized = await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized != true) {
      throw const NotificationInitializationException(
        'Failed to initialize notifications plugin',
      );
    }

    // Request permissions on iOS/macOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Create notification channel for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannel();
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    final config = _config!.notificationConfig;

    final androidChannel = AndroidNotificationChannel(
      config.channelId,
      config.channelName,
      description: config.channelDescription,
      importance: config.importance,
      enableLights: config.enableLights,
      enableVibration: config.enableVibration,
      showBadge: config.showBadge,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      _tts = FlutterTts();

      if (_tts != null) {
        await _tts!.setLanguage(_config!.ttsLanguage ?? 'en-US');
        await _tts!.setSpeechRate(_config!.ttsRate);
        await _tts!.setPitch(_config!.ttsPitch);
        await _tts!.setVolume(_config!.ttsVolume);

        _log('TTS initialized successfully');
      }
    } catch (e) {
      throw TTSInitializationException('Failed to initialize TTS: $e');
    }
  }

  /// Schedule an announcement
  Future<void> scheduleAnnouncement(ScheduledAnnouncement announcement) async {
    final config = _config!;

    // Validate against limits
    if (config.validationConfig.enableEdgeCaseValidation) {
      await _validateSchedulingLimits(announcement);
    }

    if (announcement.isRecurring) {
      await _scheduleRecurringAnnouncement(announcement);
    } else {
      await _scheduleOneTimeAnnouncement(announcement);
    }
  }

  /// Schedule a one-time announcement
  Future<void> _scheduleOneTimeAnnouncement(
    ScheduledAnnouncement announcement,
  ) async {
    final scheduledDate = tz.TZDateTime.from(
      announcement.scheduledTime,
      tz.local,
    );

    await _notifications.zonedSchedule(
      announcement.id.hashCode,
      'Scheduled Announcement',
      announcement.content,
      scheduledDate,
      _buildNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: announcement.id,
    );

    _log(
      'Scheduled one-time announcement ${announcement.id} for $scheduledDate',
    );
  }

  /// Schedule a recurring announcement
  Future<void> _scheduleRecurringAnnouncement(
    ScheduledAnnouncement announcement,
  ) async {
    final config = _config!;
    final maxDays = config.validationConfig.maxSchedulingDaysInAdvance;

    // Calculate all occurrences within the scheduling window
    final occurrences = _calculateRecurringOccurrences(
      announcement,
      DateTime.now(),
      maxDays,
    );

    // Schedule each occurrence
    for (int i = 0; i < occurrences.length; i++) {
      final occurrence = occurrences[i];
      final notificationId = announcement.id.hashCode + i;

      await _notifications.zonedSchedule(
        notificationId,
        'Recurring Announcement',
        announcement.content,
        tz.TZDateTime.from(occurrence, tz.local),
        _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '${announcement.id}_$i',
      );
    }

    _log(
      'Scheduled ${occurrences.length} recurring occurrences for ${announcement.id}',
    );
  }

  /// Calculate recurring occurrences within the specified days window
  List<DateTime> _calculateRecurringOccurrences(
    ScheduledAnnouncement announcement,
    DateTime from,
    int maxDays,
  ) {
    final occurrences = <DateTime>[];
    final targetDays = announcement.effectiveDays;
    final endDate = from.add(Duration(days: maxDays));

    var current = announcement.scheduledTime;

    // If the first occurrence is in the past, find the next valid occurrence
    while (current.isBefore(from)) {
      current = current.add(const Duration(days: 1));
      if (targetDays.contains(current.weekday)) {
        break;
      }
    }

    // Generate occurrences within the window
    while (current.isBefore(endDate)) {
      if (targetDays.contains(current.weekday)) {
        occurrences.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return occurrences;
  }

  /// Build notification details based on configuration
  NotificationDetails _buildNotificationDetails() {
    final config = _config!.notificationConfig;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        config.channelId,
        config.channelName,
        channelDescription: config.channelDescription,
        importance: config.importance,
        priority: config.priority,
        enableLights: config.enableLights,
        enableVibration: config.enableVibration,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Handle notification tap
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      _log('Notification tapped: $payload');

      // Find the announcement content and announce it
      // This is a simplified version - in practice, you'd want to
      // retrieve the full announcement details
      if (_config!.enableTTS && _tts != null) {
        try {
          // Extract announcement ID from payload
          final announcementId = payload.contains('_')
              ? payload.split('_')[0]
              : payload;

          // For this implementation, we'll announce a generic message
          // In a full implementation, you'd retrieve the announcement content
          await _tts!.speak('Announcement delivered');
          _log('TTS announcement completed for $announcementId');
        } catch (e) {
          _log('TTS announcement failed: $e');
        }
      }
    }
  }

  /// Validate scheduling limits
  Future<void> _validateSchedulingLimits(
    ScheduledAnnouncement announcement,
  ) async {
    final config = _config!.validationConfig;

    // Check total scheduled notifications limit
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();
    if (pendingNotifications.length >= config.maxScheduledNotifications) {
      throw ValidationException(
        'Cannot schedule more than ${config.maxScheduledNotifications} notifications',
      );
    }

    // For recurring announcements, estimate daily load
    if (announcement.isRecurring) {
      final dailyOccurrences = announcement.effectiveDays.length;
      if (dailyOccurrences > config.maxNotificationsPerDay) {
        throw ValidationException(
          'Recurring pattern would create $dailyOccurrences daily notifications, '
          'exceeding limit of ${config.maxNotificationsPerDay}',
        );
      }
    }
  }

  /// Cancel all scheduled announcements
  Future<void> cancelAllScheduledAnnouncements() async {
    await _notifications.cancelAll();

    // Cancel any active timers
    for (final timer in _activeAnnouncementTimers) {
      timer.cancel();
    }
    _activeAnnouncementTimers.clear();

    _log('Cancelled all scheduled announcements');
  }

  /// Cancel a specific announcement by ID
  Future<void> cancelAnnouncementById(String id) async {
    // Cancel notifications with this ID (may be multiple for recurring)
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.payload?.startsWith(id) == true) {
        await _notifications.cancel(notification.id);
        _log('Cancelled notification ${notification.id} for announcement $id');
      }
    }
  }

  /// Get all currently scheduled announcements
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();

    // This is a simplified implementation
    // In practice, you'd want to maintain a separate store of announcement metadata
    return pendingNotifications.map((notification) {
      final payload = notification.payload ?? 'unknown';
      final announcementId = payload.contains('_')
          ? payload.split('_')[0]
          : payload;

      return ScheduledAnnouncement(
        id: announcementId,
        content: notification.body ?? 'No content available',
        scheduledTime:
            DateTime.now(), // This would need to be stored separately
        isActive: true,
      );
    }).toList();
  }

  /// Dispose resources
  Future<void> dispose() async {
    // Cancel any active timers
    for (final timer in _activeAnnouncementTimers) {
      timer.cancel();
    }
    _activeAnnouncementTimers.clear();

    // Dispose TTS
    if (_tts != null) {
      await _tts!.stop();
    }
  }

  /// Log debug information if enabled
  void _log(String message) {
    if (_config?.enableDebugLogging == true) {
      debugPrint('[AnnouncementService] $message');
    }
  }
}
