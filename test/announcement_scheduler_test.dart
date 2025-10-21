import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnnouncementScheduler Public API', () {
    test('AnnouncementConfig can be instantiated with required parameters', () {
      expect(
        () => AnnouncementConfig(
          notificationConfig: NotificationConfig(
            channelId: 'test',
            channelName: 'Test',
          ),
        ),
        returnsNormally,
        reason: 'AnnouncementConfig should accept minimal required parameters',
      );
    });

    test('AnnouncementConfig validates TTS rate constraints', () {
      expect(
        () => AnnouncementConfig(
          ttsRate: 1.5, // Invalid: must be between 0.0 and 1.0
          notificationConfig: const NotificationConfig(),
        ),
        throwsAssertionError,
        reason: 'TTS rate must be validated to be between 0.0 and 1.0',
      );
    });

    test('AnnouncementConfig validates TTS pitch constraints', () {
      expect(
        () => AnnouncementConfig(
          ttsPitch: 0.3, // Invalid: must be between 0.5 and 2.0
          notificationConfig: const NotificationConfig(),
        ),
        throwsAssertionError,
        reason: 'TTS pitch must be validated to be between 0.5 and 2.0',
      );
    });

    test('AnnouncementConfig validates TTS volume constraints', () {
      expect(
        () => AnnouncementConfig(
          ttsVolume: 1.5, // Invalid: must be between 0.0 and 1.0
          notificationConfig: const NotificationConfig(),
        ),
        throwsAssertionError,
        reason: 'TTS volume must be validated to be between 0.0 and 1.0',
      );
    });

    test('AnnouncementConfig requires timezoneLocation when forceTimezone', () {
      expect(
        () => AnnouncementConfig(
          forceTimezone: true,
          timezoneLocation:
              null, // Invalid: required when forceTimezone is true
          notificationConfig: NotificationConfig(),
        ),
        throwsAssertionError,
        reason: 'timezoneLocation must be provided when forceTimezone is true',
      );
    });

    test('AnnouncementConfig copyWith creates new instance with changes', () {
      const original = AnnouncementConfig(
        enableTTS: true,
        ttsRate: 0.5,
        notificationConfig: NotificationConfig(),
      );

      final modified = original.copyWith(enableTTS: false, ttsRate: 0.7);

      expect(
        modified.enableTTS,
        false,
        reason: 'copyWith should update enableTTS',
      );
      expect(modified.ttsRate, 0.7, reason: 'copyWith should update ttsRate');
      expect(
        modified.notificationConfig,
        original.notificationConfig,
        reason: 'copyWith should preserve unchanged values',
      );
    });

    test('NotificationConfig has sensible defaults', () {
      const config = NotificationConfig();

      expect(
        config.channelId,
        'scheduled_announcements',
        reason: 'Default channel ID should be set',
      );
      expect(
        config.channelName,
        'Scheduled Announcements',
        reason: 'Default channel name should be set',
      );
      expect(
        config.importance,
        Importance.high,
        reason: 'Default importance should be high',
      );
      expect(
        config.priority,
        Priority.high,
        reason: 'Default priority should be high',
      );
      expect(config.showBadge, true, reason: 'Default should show badge');
      expect(config.enableLights, true, reason: 'Default should enable lights');
      expect(
        config.enableVibration,
        true,
        reason: 'Default should enable vibration',
      );
    });

    test('ValidationConfig has sensible defaults', () {
      const config = ValidationConfig();

      expect(
        config.maxNotificationsPerDay,
        10,
        reason: 'Default should allow 10 notifications per day',
      );
      expect(
        config.maxScheduledNotifications,
        50,
        reason: 'Default should allow 50 total scheduled notifications',
      );
      expect(
        config.enableEdgeCaseValidation,
        true,
        reason: 'Edge case validation should be enabled by default',
      );
      expect(
        config.enableTimezoneValidation,
        true,
        reason: 'Timezone validation should be enabled by default',
      );
      expect(
        config.minAnnouncementIntervalMinutes,
        1,
        reason: 'Minimum interval should be 1 minute',
      );
      expect(
        config.maxSchedulingDaysInAdvance,
        14,
        reason: 'Default should schedule 14 days in advance',
      );
    });

    test('RecurrencePattern.daily returns all days of the week', () {
      final days = RecurrencePattern.daily.defaultDays;

      expect(days, [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ], reason: 'Daily pattern should include all 7 days');
    });

    test('RecurrencePattern.weekdays returns Monday through Friday', () {
      final days = RecurrencePattern.weekdays.defaultDays;

      expect(days, [
        1,
        2,
        3,
        4,
        5,
      ], reason: 'Weekdays pattern should include Monday-Friday');
    });

    test('RecurrencePattern.weekends returns Saturday and Sunday', () {
      final days = RecurrencePattern.weekends.defaultDays;

      expect(days, [
        6,
        7,
      ], reason: 'Weekends pattern should include Saturday-Sunday');
    });

    test('RecurrencePattern.custom returns empty list', () {
      final days = RecurrencePattern.custom.defaultDays;

      expect(
        days,
        isEmpty,
        reason: 'Custom pattern should have no default days',
      );
    });

    test('RecurrencePattern has display names', () {
      expect(
        RecurrencePattern.daily.displayName,
        'Daily',
        reason: 'Daily should have display name',
      );
      expect(
        RecurrencePattern.weekdays.displayName,
        'Weekdays',
        reason: 'Weekdays should have display name',
      );
      expect(
        RecurrencePattern.weekends.displayName,
        'Weekends',
        reason: 'Weekends should have display name',
      );
      expect(
        RecurrencePattern.custom.displayName,
        'Custom',
        reason: 'Custom should have display name',
      );
    });

    test('ScheduledAnnouncement identifies recurring vs one-time', () {
      final recurring = ScheduledAnnouncement(
        id: 'test_recurring',
        content: 'Test',
        scheduledTime: DateTime.now(),
        recurrence: RecurrencePattern.daily,
      );

      final oneTime = ScheduledAnnouncement(
        id: 'test_onetime',
        content: 'Test',
        scheduledTime: DateTime.now(),
      );

      expect(
        recurring.isRecurring,
        true,
        reason: 'Should identify recurring announcements',
      );
      expect(
        recurring.isOneTime,
        false,
        reason: 'Recurring should not be one-time',
      );
      expect(
        oneTime.isRecurring,
        false,
        reason: 'One-time should not be recurring',
      );
      expect(
        oneTime.isOneTime,
        true,
        reason: 'Should identify one-time announcements',
      );
    });

    test('ScheduledAnnouncement returns effective days correctly', () {
      final daily = ScheduledAnnouncement(
        id: 'test',
        content: 'Test',
        scheduledTime: DateTime.now(),
        recurrence: RecurrencePattern.daily,
      );

      final custom = ScheduledAnnouncement(
        id: 'test',
        content: 'Test',
        scheduledTime: DateTime.now(),
        recurrence: RecurrencePattern.custom,
        customDays: [1, 3, 5],
      );

      final oneTime = ScheduledAnnouncement(
        id: 'test',
        content: 'Test',
        scheduledTime: DateTime.now(),
      );

      expect(daily.effectiveDays, [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ], reason: 'Daily should return all days');
      expect(custom.effectiveDays, [
        1,
        3,
        5,
      ], reason: 'Custom should return specified days');
      expect(
        oneTime.effectiveDays,
        isEmpty,
        reason: 'One-time should return empty list',
      );
    });

    test('AnnouncementStatus has display names', () {
      expect(
        AnnouncementStatus.scheduled.displayName,
        'Scheduled',
        reason: 'Scheduled status should have display name',
      );
      expect(
        AnnouncementStatus.delivering.displayName,
        'Delivering',
        reason: 'Delivering status should have display name',
      );
      expect(
        AnnouncementStatus.completed.displayName,
        'Completed',
        reason: 'Completed status should have display name',
      );
      expect(
        AnnouncementStatus.failed.displayName,
        'Failed',
        reason: 'Failed status should have display name',
      );
    });

    test('AnnouncementStatus identifies active vs complete states', () {
      expect(
        AnnouncementStatus.scheduled.isActive,
        true,
        reason: 'Scheduled should be active',
      );
      expect(
        AnnouncementStatus.delivering.isActive,
        true,
        reason: 'Delivering should be active',
      );
      expect(
        AnnouncementStatus.completed.isActive,
        false,
        reason: 'Completed should not be active',
      );
      expect(
        AnnouncementStatus.failed.isActive,
        false,
        reason: 'Failed should not be active',
      );

      expect(
        AnnouncementStatus.scheduled.isComplete,
        false,
        reason: 'Scheduled should not be complete',
      );
      expect(
        AnnouncementStatus.delivering.isComplete,
        false,
        reason: 'Delivering should not be complete',
      );
      expect(
        AnnouncementStatus.completed.isComplete,
        true,
        reason: 'Completed should be complete',
      );
      expect(
        AnnouncementStatus.failed.isComplete,
        true,
        reason: 'Failed should be complete',
      );
    });

    test('Exceptions have appropriate messages', () {
      const permissionDenied = NotificationPermissionDeniedException();
      expect(
        permissionDenied.message,
        contains('permission denied'),
        reason: 'Permission denied exception should have descriptive message',
      );

      const initError = NotificationInitializationException('Init failed');
      expect(
        initError.message,
        'Init failed',
        reason: 'Should preserve custom error message',
      );

      const validation = ValidationException('Invalid input');
      expect(
        validation.message,
        'Invalid input',
        reason: 'Should preserve validation message',
      );

      const ttsInit = TTSInitializationException('TTS unavailable');
      expect(
        ttsInit.message,
        'TTS unavailable',
        reason: 'Should preserve TTS error message',
      );

      const ttsAnnounce = TTSAnnouncementException('Speech failed');
      expect(
        ttsAnnounce.message,
        'Speech failed',
        reason: 'Should preserve TTS announcement error message',
      );

      const scheduling = NotificationSchedulingException('Scheduling failed');
      expect(
        scheduling.message,
        'Scheduling failed',
        reason: 'Should preserve scheduling error message',
      );
    });

    test('All exceptions extend AnnouncementException', () {
      expect(
        const NotificationPermissionDeniedException(),
        isA<AnnouncementException>(),
        reason: 'Should extend base exception',
      );
      expect(
        const NotificationInitializationException('test'),
        isA<AnnouncementException>(),
        reason: 'Should extend base exception',
      );
      expect(
        const ValidationException('test'),
        isA<AnnouncementException>(),
        reason: 'Should extend base exception',
      );
      expect(
        const TTSInitializationException('test'),
        isA<AnnouncementException>(),
        reason: 'Should extend base exception',
      );
      expect(
        const TTSAnnouncementException('test'),
        isA<AnnouncementException>(),
        reason: 'Should extend base exception',
      );
      expect(
        const NotificationSchedulingException('test'),
        isA<AnnouncementException>(),
        reason: 'Should extend base exception',
      );
    });
  });

  group('AnnouncementScheduler API Design', () {
    test('Public API exports are accessible', () {
      // Verify all expected types are exported and accessible
      expect(
        AnnouncementScheduler,
        isNotNull,
        reason: 'AnnouncementScheduler should be exported',
      );
      expect(
        AnnouncementConfig,
        isNotNull,
        reason: 'AnnouncementConfig should be exported',
      );
      expect(
        NotificationConfig,
        isNotNull,
        reason: 'NotificationConfig should be exported',
      );
      expect(
        ValidationConfig,
        isNotNull,
        reason: 'ValidationConfig should be exported',
      );
      expect(
        ScheduledAnnouncement,
        isNotNull,
        reason: 'ScheduledAnnouncement should be exported',
      );
      expect(
        RecurrencePattern,
        isNotNull,
        reason: 'RecurrencePattern should be exported',
      );
      expect(
        AnnouncementStatus,
        isNotNull,
        reason: 'AnnouncementStatus should be exported',
      );

      // Verify exception types are exported
      expect(
        AnnouncementException,
        isNotNull,
        reason: 'AnnouncementException should be exported',
      );
      expect(
        ValidationException,
        isNotNull,
        reason: 'ValidationException should be exported',
      );
      expect(
        NotificationPermissionDeniedException,
        isNotNull,
        reason: 'NotificationPermissionDeniedException should be exported',
      );
      expect(
        NotificationInitializationException,
        isNotNull,
        reason: 'NotificationInitializationException should be exported',
      );
      expect(
        NotificationSchedulingException,
        isNotNull,
        reason: 'NotificationSchedulingException should be exported',
      );
      expect(
        TTSInitializationException,
        isNotNull,
        reason: 'TTSInitializationException should be exported',
      );
      expect(
        TTSAnnouncementException,
        isNotNull,
        reason: 'TTSAnnouncementException should be exported',
      );

      // Verify re-exported dependency types are accessible
      expect(
        Importance,
        isNotNull,
        reason: 'Importance should be re-exported for convenience',
      );
      expect(
        Priority,
        isNotNull,
        reason: 'Priority should be re-exported for convenience',
      );
    });
  });
}
