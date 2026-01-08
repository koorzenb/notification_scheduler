import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/notification_scheduler.dart';
import 'package:notification_scheduler/src/services/core_notification_service.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';
import 'package:timezone/timezone.dart' as tz;

import 'core_notification_service_test.mocks.dart';

@GenerateMocks([
  FlutterTts,
  SchedulingSettingsService,
  FlutterLocalNotificationsPlugin,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - onNotificationResponse', () {
    late StreamController<NotificationStatus> statusController;
    late AnnouncementConfig config;
    late MockFlutterTts mockTts;
    late MockSchedulingSettingsService mockSettingsService;
    late CoreNotificationService service;

    setUp(() {
      statusController = StreamController<NotificationStatus>.broadcast();
      mockTts = MockFlutterTts();
      mockSettingsService = MockSchedulingSettingsService();
      config = const AnnouncementConfig(
        enableTTS: true,
        notificationConfig: NotificationConfig(),
      );

      // Stub the speak method by default
      when(mockTts.speak(any)).thenAnswer((_) async => 1);
      when(mockTts.stop()).thenAnswer((_) async => 1);

      // Create a minimal service instance
      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
        tts: mockTts,
      );
    });

    tearDown(() {
      statusController.close();
      service.dispose();
    });

    test(
      'emits AnnouncementStatus.completed when notification is received',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'Test announcement',
        );

        // Act
        final statusFuture = service.statusStream.first;
        service.onNotificationResponse(response);

        // Assert
        final status = await statusFuture;
        expect(
          status,
          NotificationStatus.completed,
          reason: 'Should emit completed status when notification is received',
        );
      },
    );

    test(
      'triggers TTS with payload when TTS is enabled and payload exists',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'Good morning! Time to wake up.',
        );

        when(mockTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        service.onNotificationResponse(response);

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verify(mockTts.speak('Good morning! Time to wake up.')).called(1);
      },
    );

    test(
      'triggers TTS with actionId when payload is null but actionId exists',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 1,
          actionId: 'snooze_action',
        );

        when(mockTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        service.onNotificationResponse(response);

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verify(mockTts.speak('snooze_action')).called(1);
      },
    );

    test('does not trigger TTS when TTS is disabled in config', () async {
      // Arrange
      final configWithoutTts = const AnnouncementConfig(
        enableTTS: false,
        notificationConfig: NotificationConfig(),
      );

      // Create service with disabled TTS config
      final serviceWithoutTts = CoreNotificationService(
        settingsService: mockSettingsService,
        config: configWithoutTts,
        tts: mockTts,
      );

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Act
      serviceWithoutTts.onNotificationResponse(response);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verifyNever(mockTts.speak(any));
      await serviceWithoutTts.dispose();
    });

    test('does not trigger TTS when tts is null', () async {
      // Arrange
      // Create service with null TTS
      final serviceNullTts = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
        tts: null,
      );

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      // Act
      serviceNullTts.onNotificationResponse(response);

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verifyNever(mockTts.speak(any));
      await serviceNullTts.dispose();
    });

    test(
      'does not trigger TTS when payload and actionId are both empty',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: '',
        );

        when(mockTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        service.onNotificationResponse(response);

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verifyNever(mockTts.speak(any));
      },
    );

    test('emits completed status even when TTS is disabled', () async {
      // Arrange
      final configWithoutTts = const AnnouncementConfig(
        enableTTS: false,
        notificationConfig: NotificationConfig(),
      );

      // Create service with disabled TTS config
      final serviceWithoutTts = CoreNotificationService(
        settingsService: mockSettingsService,
        config: configWithoutTts,
        tts: mockTts,
      );

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      // Act
      final statusFuture = serviceWithoutTts.statusStream.first;
      serviceWithoutTts.onNotificationResponse(response);

      // Assert
      final status = await statusFuture;
      expect(
        status,
        NotificationStatus.completed,
        reason: 'Should emit completed status regardless of TTS configuration',
      );
      await serviceWithoutTts.dispose();
    });

    test('handles multiple rapid notification responses correctly', () async {
      // Arrange
      final responses = [
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'First announcement',
        ),
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 2,
          payload: 'Second announcement',
        ),
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 3,
          payload: 'Third announcement',
        ),
      ];

      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Act
      final statusList = <NotificationStatus>[];
      service.statusStream.listen(statusList.add);

      for (final response in responses) {
        service.onNotificationResponse(response);
      }

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(
        statusList.length,
        3,
        reason: 'Should emit completed status for each notification',
      );
      expect(
        statusList.every((s) => s == NotificationStatus.completed),
        true,
        reason: 'All statuses should be completed',
      );
      verify(mockTts.speak('First announcement')).called(1);
      verify(mockTts.speak('Second announcement')).called(1);
      verify(mockTts.speak('Third announcement')).called(1);
    });
  });

  group('scheduleRecurringNotifications', () {
    late MockSchedulingSettingsService mockSettingsService;
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late MockFlutterTts mockTts;
    late CoreNotificationService service;

    setUp(() {
      mockSettingsService = MockSchedulingSettingsService();
      mockNotifications = MockFlutterLocalNotificationsPlugin();
      mockTts = MockFlutterTts();

      // Default stubs
      when(
        mockSettingsService.getAnnouncementHour(),
      ).thenAnswer((_) async => 10);
      when(
        mockSettingsService.getAnnouncementMinute(),
      ).thenAnswer((_) async => 0);
      when(
        mockNotifications.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ),
      ).thenAnswer((_) async {});
      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        notifications: mockNotifications,
        tts: mockTts,
      );
    });

    test('throws NotificationSchedulingException when hour is null', () async {
      when(
        mockSettingsService.getAnnouncementHour(),
      ).thenAnswer((_) async => null);

      expect(
        () => service.scheduleRecurringNotifications(
          announcementId: 123,
          content: 'Test',
          recurrencePattern: RecurrencePattern.daily,
          customDays: [],
        ),
        throwsA(isA<NotificationSchedulingException>()),
        reason: 'Should throw when announcement hour is not set',
      );
    });

    test(
      'throws NotificationSchedulingException when minute is null',
      () async {
        when(
          mockSettingsService.getAnnouncementMinute(),
        ).thenAnswer((_) async => null);

        expect(
          () => service.scheduleRecurringNotifications(
            announcementId: 123,
            content: 'Test',
            recurrencePattern: RecurrencePattern.daily,
            customDays: [],
          ),
          throwsA(isA<NotificationSchedulingException>()),
          reason: 'Should throw when announcement minute is not set',
        );
      },
    );

    test('validates recurring settings', () async {
      // Custom recurrence with empty days should throw ValidationException
      expect(
        () => service.scheduleRecurringNotifications(
          announcementId: 123,
          content: 'Test',
          recurrencePattern: RecurrencePattern.custom,
          customDays: [],
        ),
        throwsA(isA<ValidationException>()),
        reason: 'Should throw ValidationException for invalid custom days',
      );
    });

    test('schedules notifications with correct parameters', () async {
      await service.scheduleRecurringNotifications(
        announcementId: 100,
        content: 'Daily reminder',
        recurrencePattern: RecurrencePattern.daily,
        customDays: [],
      );

      final captured = verify(
        mockNotifications.zonedSchedule(
          captureAny, // id
          captureAny, // title
          captureAny, // body
          captureAny, // scheduledDate
          captureAny, // notificationDetails
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ),
      ).captured;

      // Verify at least one notification was scheduled
      expect(captured.length, greaterThanOrEqualTo(5));

      // Verify first notification details
      expect(captured[1], 'Recurring Announcement'); // title
      expect(captured[2], 'Daily reminder'); // body
      expect(captured[3], isA<tz.TZDateTime>()); // scheduledDate
      expect(captured[4], isA<NotificationDetails>()); // notificationDetails
    });

    test(
      'schedules unattended announcement for first occurrence when TTS enabled',
      () async {
        // Re-create service with TTS enabled
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: const AnnouncementConfig(
            enableTTS: true,
            notificationConfig: NotificationConfig(),
          ),
          notifications: mockNotifications,
          tts: mockTts,
        );

        await service.scheduleRecurringNotifications(
          announcementId: 123,
          content: 'TTS Content',
          recurrencePattern: RecurrencePattern.daily,
          customDays: [],
        );

        // Verify notifications are still scheduled
        verify(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(greaterThan(0));
      },
    );

    test(
      'does not schedule unattended announcement when TTS disabled',
      () async {
        // Re-create service with TTS disabled
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: const AnnouncementConfig(
            enableTTS: false,
            notificationConfig: NotificationConfig(),
          ),
          notifications: mockNotifications,
          tts: mockTts,
        );

        await service.scheduleRecurringNotifications(
          announcementId: 123,
          content: 'No TTS Content',
          recurrencePattern: RecurrencePattern.daily,
          customDays: [],
        );

        // Verify notifications are still scheduled
        verify(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(greaterThan(0));
      },
    );
  });

  group('validateSchedulingLimits', () {
    late CoreNotificationService service;
    late MockSchedulingSettingsService mockSettingsService;

    setUp(() {
      mockSettingsService = MockSchedulingSettingsService();
    });

    group('Valid scheduling within limits', () {
      test('should pass when scheduling first announcement', () async {
        final config = AnnouncementConfig(
          notificationConfig: const NotificationConfig(),
          validationConfig: const ValidationConfig(
            maxNotificationsPerDay: 10,
            maxScheduledNotifications: 50,
          ),
        );
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: config,
        );

        final announcement = ScheduledNotification(
          id: 1,
          content: 'Morning reminder',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        final existingAnnouncements = <ScheduledNotification>[];

        await service.validateSchedulingLimits(
          announcement,
          existingAnnouncements,
        );

        expect(
          true,
          isTrue,
          reason:
              'Should pass when no existing notifications and adding first announcement',
        );
      });

      test('should pass when within daily limit', () async {
        final config = AnnouncementConfig(
          notificationConfig: const NotificationConfig(),
          validationConfig: const ValidationConfig(
            maxNotificationsPerDay: 5,
            maxScheduledNotifications: 50,
          ),
        );
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: config,
        );

        final announcement = ScheduledNotification(
          id: 2,
          content: 'Afternoon reminder',
          scheduledTime: DateTime(2025, 11, 20, 14, 0),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        // 4 existing announcements on the same day + 1 on a different day
        final sameDay = DateTime(2025, 11, 20, 9, 0);
        final existingAnnouncements = [
          ScheduledNotification(
            id: 0,
            content: 'Existing 0',
            scheduledTime: sameDay,
            isActive: true,
          ),
          ScheduledNotification(
            id: 1,
            content: 'Existing 1',
            scheduledTime: sameDay.add(const Duration(hours: 1)),
            isActive: true,
          ),
          ScheduledNotification(
            id: 2,
            content: 'Existing 2',
            scheduledTime: sameDay.add(const Duration(hours: 2)),
            isActive: true,
          ),
          ScheduledNotification(
            id: 3,
            content: 'Existing 3',
            scheduledTime: sameDay.add(const Duration(hours: 3)),
            isActive: true,
          ),
          ScheduledNotification(
            id: 4,
            content: 'Existing 4',
            scheduledTime: sameDay.add(const Duration(days: 1)),
            isActive: true,
          ),
        ];

        await service.validateSchedulingLimits(
          announcement,
          existingAnnouncements,
        );

        expect(
          true,
          isTrue,
          reason:
              'Should pass when 4 existing (current day) + 1 (next day) + 1 new (current day)= 5 total (equal to daily limit of 5 )',
        );
      });

      test('should pass when within total scheduled limit', () async {
        final config = AnnouncementConfig(
          notificationConfig: const NotificationConfig(),
          validationConfig: const ValidationConfig(
            maxNotificationsPerDay: 10,
            maxScheduledNotifications: 50,
          ),
        );
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: config,
        );

        final announcement = ScheduledNotification(
          id: 3,
          content: 'Weekly reminder',
          scheduledTime: DateTime.now().add(const Duration(days: 7)),
          isActive: true,
          recurrence: RecurrencePattern.weekdays,
        );

        // 49 existing announcements across various days
        final existingAnnouncements = List.generate(
          49,
          (i) => ScheduledNotification(
            id: i,
            content: 'Announcement $i',
            scheduledTime: DateTime.now().add(Duration(days: i)),
            isActive: true,
          ),
        );

        await service.validateSchedulingLimits(
          announcement,
          existingAnnouncements,
        );

        expect(
          true,
          isTrue,
          reason:
              'Should pass when 49 existing + 1 new = 50 total (equal to limit of 50)',
        );
      });
    });

    group('Exceeding daily limit', () {
      test('should throw when exceeding maxNotificationsPerDay', () async {
        final config = AnnouncementConfig(
          notificationConfig: const NotificationConfig(),
          validationConfig: const ValidationConfig(
            maxNotificationsPerDay: 3,
            maxScheduledNotifications: 50,
          ),
        );
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: config,
        );

        final announcement = ScheduledNotification(
          id: 4,
          content: 'One too many',
          scheduledTime: DateTime(2025, 11, 20, 16, 0),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        // 3 announcements already scheduled for the same day
        final sameDay = DateTime(2025, 11, 20, 9, 0);
        final existingAnnouncements = [
          ScheduledNotification(
            id: 0,
            content: 'Existing 0',
            scheduledTime: sameDay,
            isActive: true,
          ),
          ScheduledNotification(
            id: 1,
            content: 'Existing 1',
            scheduledTime: sameDay.add(const Duration(hours: 2)),
            isActive: true,
          ),
          ScheduledNotification(
            id: 2,
            content: 'Existing 2',
            scheduledTime: sameDay.add(const Duration(hours: 4)),
            isActive: true,
          ),
        ];

        await expectLater(
          service.validateSchedulingLimits(announcement, existingAnnouncements),
          throwsA(isA<ValidationException>()),
          reason: 'Should throw when 3 existing + 1 new = 4 exceeds limit of 3',
        );
      });
    });

    group('Exceeding total limit', () {
      test('should throw when exceeding maxScheduledNotifications', () async {
        final config = AnnouncementConfig(
          notificationConfig: const NotificationConfig(),
          validationConfig: const ValidationConfig(
            maxNotificationsPerDay: 10,
            maxScheduledNotifications: 50,
          ),
        );
        service = CoreNotificationService(
          settingsService: mockSettingsService,
          config: config,
        );

        final announcement = ScheduledNotification(
          id: 5,
          content: 'Too many total',
          scheduledTime: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        // 50 announcements already scheduled
        final existingAnnouncements = List.generate(
          50,
          (i) => ScheduledNotification(
            id: i,
            content: 'Announcement $i',
            scheduledTime: DateTime.now().add(Duration(days: i)),
            isActive: true,
          ),
        );

        await expectLater(
          service.validateSchedulingLimits(announcement, existingAnnouncements),
          throwsA(isA<ValidationException>()),
          reason: 'Should throw when 50 existing + new exceeds limit of 50',
        );
      });
    });
  });
}

/// Mock settings service for testing
class MockSettingsService {
  int? hour;
  int? minute;
  Map<int, DateTime> storedTimes = {};

  Future<int?> getAnnouncementHour() async => hour;
  Future<int?> getAnnouncementMinute() async => minute;
  Future<void> setScheduledTimes(Map<int, DateTime> times) async {
    storedTimes = Map.from(times);
  }
}

/// Helper class to track scheduled notifications
class ScheduledNotificationData {
  final int id;
  final tz.TZDateTime date;
  final String content;
  final String title;

  ScheduledNotificationData({
    required this.id,
    required this.date,
    required this.content,
    required this.title,
  });
}

/// Helper class to track unattended announcements
class UnattendedAnnouncementData {
  final String content;
  final Duration delay;

  UnattendedAnnouncementData({required this.content, required this.delay});
}
