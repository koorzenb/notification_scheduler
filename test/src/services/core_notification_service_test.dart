import 'dart:async';

import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:announcement_scheduler/src/services/core_notification_service.dart';
import 'package:announcement_scheduler/src/services/scheduling_settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/timezone.dart' as tz;

import 'core_notification_service_test.mocks.dart';

@GenerateMocks([FlutterTts, SchedulingSettingsService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - onNotificationResponse', () {
    late StreamController<AnnouncementStatus> statusController;
    late AnnouncementConfig config;
    late MockFlutterTts mockTts;
    late MockSchedulingSettingsService mockSettingsService;
    late CoreNotificationService service;

    setUp(() {
      statusController = StreamController<AnnouncementStatus>.broadcast();
      mockTts = MockFlutterTts();
      mockSettingsService = MockSchedulingSettingsService();
      config = const AnnouncementConfig(
        enableTTS: true,
        notificationConfig: NotificationConfig(),
      );

      // Stub the speak method by default
      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Create a minimal service instance
      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
      );
    });

    tearDown(() {
      statusController.close();
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
        final statusFuture = statusController.stream.first;
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

        // Assert
        final status = await statusFuture;
        expect(
          status,
          AnnouncementStatus.completed,
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
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

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
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

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

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Act
      service.onNotificationResponse(
        response,
        statusController,
        configWithoutTts,
        mockTts,
      );

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verifyNever(mockTts.speak(any));
    });

    test('does not trigger TTS when tts is null', () async {
      // Arrange
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      // Act
      service.onNotificationResponse(
        response,
        statusController,
        config,
        null, // No TTS instance
      );

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verifyNever(mockTts.speak(any));
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
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

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

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      // Act
      final statusFuture = statusController.stream.first;
      service.onNotificationResponse(
        response,
        statusController,
        configWithoutTts,
        mockTts,
      );

      // Assert
      final status = await statusFuture;
      expect(
        status,
        AnnouncementStatus.completed,
        reason: 'Should emit completed status regardless of TTS configuration',
      );
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
      final statusList = <AnnouncementStatus>[];
      statusController.stream.listen(statusList.add);

      for (final response in responses) {
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );
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
        statusList.every((s) => s == AnnouncementStatus.completed),
        true,
        reason: 'All statuses should be completed',
      );
      verify(mockTts.speak('First announcement')).called(1);
      verify(mockTts.speak('Second announcement')).called(1);
      verify(mockTts.speak('Third announcement')).called(1);
    });
  });

  group('scheduleRecurringNotifications', () {
    late MockSettingsService mockSettings;
    late List<ScheduledNotificationData> scheduledNotifications;
    late List<UnattendedAnnouncementData> unattendedAnnouncements;

    setUp(() {
      mockSettings = MockSettingsService();
      scheduledNotifications = [];
      unattendedAnnouncements = [];
    });

    test('throws NotificationSchedulingException when hour is null', () async {
      mockSettings.hour = null;
      mockSettings.minute = 30;

      expect(
        () => CoreNotificationService.scheduleRecurringNotificationsImpl(
          content: 'Test',
          recurrencePattern: RecurrencePattern.daily,
          customDays: [],
          config: const AnnouncementConfig(
            notificationConfig: NotificationConfig(),
          ),
          getAnnouncementHour: mockSettings.getAnnouncementHour,
          getAnnouncementMinute: mockSettings.getAnnouncementMinute,
          setScheduledTimes: mockSettings.setScheduledTimes,
          getRecurringDates:
              ({
                required recurrencePattern,
                required customDays,
                required startDate,
                required maxDays,
              }) => [],
          validateRecurringSettings: (pattern, days) async {},
          scheduleRecurringNotification:
              ({
                required notificationId,
                required scheduledDate,
                required content,
                required title,
              }) async {},
          scheduleUnattendedAnnouncement: (content, delay) {},
        ),
        throwsA(isA<NotificationSchedulingException>()),
        reason: 'Should throw when announcement hour is not set',
      );
    });

    test(
      'throws NotificationSchedulingException when minute is null',
      () async {
        mockSettings.hour = 10;
        mockSettings.minute = null;

        expect(
          () => CoreNotificationService.scheduleRecurringNotificationsImpl(
            content: 'Test',
            recurrencePattern: RecurrencePattern.daily,
            customDays: [],
            config: const AnnouncementConfig(
              notificationConfig: NotificationConfig(),
            ),
            getAnnouncementHour: mockSettings.getAnnouncementHour,
            getAnnouncementMinute: mockSettings.getAnnouncementMinute,
            setScheduledTimes: mockSettings.setScheduledTimes,
            getRecurringDates:
                ({
                  required recurrencePattern,
                  required customDays,
                  required startDate,
                  required maxDays,
                }) => [],
            validateRecurringSettings: (pattern, days) async {},
            scheduleRecurringNotification:
                ({
                  required notificationId,
                  required scheduledDate,
                  required content,
                  required title,
                }) async {},
            scheduleUnattendedAnnouncement: (content, delay) {},
          ),
          throwsA(isA<NotificationSchedulingException>()),
          reason: 'Should throw when announcement minute is not set',
        );
      },
    );

    test('calls validateRecurringSettings with correct parameters', () async {
      mockSettings.hour = 10;
      mockSettings.minute = 30;
      RecurrencePattern? receivedPattern;
      List<int>? receivedDays;

      await CoreNotificationService.scheduleRecurringNotificationsImpl(
        content: 'Test',
        recurrencePattern: RecurrencePattern.custom,
        customDays: [1, 3, 5],
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        getAnnouncementHour: mockSettings.getAnnouncementHour,
        getAnnouncementMinute: mockSettings.getAnnouncementMinute,
        setScheduledTimes: mockSettings.setScheduledTimes,
        getRecurringDates:
            ({
              required recurrencePattern,
              required customDays,
              required startDate,
              required maxDays,
            }) => [],
        validateRecurringSettings: (pattern, days) async {
          receivedPattern = pattern;
          receivedDays = days;
        },
        scheduleRecurringNotification:
            ({
              required notificationId,
              required scheduledDate,
              required content,
              required title,
            }) async {},
        scheduleUnattendedAnnouncement: (content, delay) {},
      );

      expect(
        receivedPattern,
        equals(RecurrencePattern.custom),
        reason: 'Recurrence pattern should be passed to validation',
      );
      expect(
        receivedDays,
        equals([1, 3, 5]),
        reason: 'Custom days should be passed to validation',
      );
    });

    test('calls getRecurringDates with maxDays of 14', () async {
      mockSettings.hour = 8;
      mockSettings.minute = 45;
      int? receivedMaxDays;

      await CoreNotificationService.scheduleRecurringNotificationsImpl(
        content: 'Test',
        recurrencePattern: RecurrencePattern.weekdays,
        customDays: [],
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        getAnnouncementHour: mockSettings.getAnnouncementHour,
        getAnnouncementMinute: mockSettings.getAnnouncementMinute,
        setScheduledTimes: mockSettings.setScheduledTimes,
        getRecurringDates:
            ({
              required recurrencePattern,
              required customDays,
              required startDate,
              required maxDays,
            }) {
              receivedMaxDays = maxDays;
              return [];
            },
        validateRecurringSettings: (pattern, days) async {},
        scheduleRecurringNotification:
            ({
              required notificationId,
              required scheduledDate,
              required content,
              required title,
            }) async {},
        scheduleUnattendedAnnouncement: (content, delay) {},
      );

      expect(
        receivedMaxDays,
        equals(14),
        reason: 'Max days should be 14 (Android limitation)',
      );
    });

    test('schedules notifications for each returned date', () async {
      mockSettings.hour = 10;
      mockSettings.minute = 0;

      final testDates = [
        tz.TZDateTime.now(tz.local).add(const Duration(days: 1)),
        tz.TZDateTime.now(tz.local).add(const Duration(days: 2)),
        tz.TZDateTime.now(tz.local).add(const Duration(days: 3)),
      ];

      await CoreNotificationService.scheduleRecurringNotificationsImpl(
        content: 'Daily reminder',
        recurrencePattern: RecurrencePattern.daily,
        customDays: [],
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        getAnnouncementHour: mockSettings.getAnnouncementHour,
        getAnnouncementMinute: mockSettings.getAnnouncementMinute,
        setScheduledTimes: mockSettings.setScheduledTimes,
        getRecurringDates:
            ({
              required recurrencePattern,
              required customDays,
              required startDate,
              required maxDays,
            }) => testDates,
        validateRecurringSettings: (pattern, days) async {},
        scheduleRecurringNotification:
            ({
              required notificationId,
              required scheduledDate,
              required content,
              required title,
            }) async {
              scheduledNotifications.add(
                ScheduledNotificationData(
                  id: notificationId,
                  date: scheduledDate,
                  content: content,
                  title: title,
                ),
              );
            },
        scheduleUnattendedAnnouncement: (content, delay) {},
      );

      expect(
        scheduledNotifications.length,
        equals(3),
        reason: 'Should schedule one notification per date',
      );
      expect(
        scheduledNotifications[0].content,
        equals('Daily reminder'),
        reason: 'Content should be passed to each notification',
      );
      expect(
        scheduledNotifications[0].title,
        equals('Recurring Announcement'),
        reason: 'Title should be "Recurring Announcement"',
      );
      expect(
        scheduledNotifications[0].id,
        equals(0),
        reason: 'First notification should have ID 0',
      );
      expect(
        scheduledNotifications[2].id,
        equals(2),
        reason: 'Third notification should have ID 2',
      );
    });

    test('stores scheduled times for all notifications', () async {
      mockSettings.hour = 14;
      mockSettings.minute = 30;

      final testDates = [
        tz.TZDateTime.now(tz.local).add(const Duration(days: 1)),
        tz.TZDateTime.now(tz.local).add(const Duration(days: 2)),
      ];

      await CoreNotificationService.scheduleRecurringNotificationsImpl(
        content: 'Test',
        recurrencePattern: RecurrencePattern.daily,
        customDays: [],
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        getAnnouncementHour: mockSettings.getAnnouncementHour,
        getAnnouncementMinute: mockSettings.getAnnouncementMinute,
        setScheduledTimes: mockSettings.setScheduledTimes,
        getRecurringDates:
            ({
              required recurrencePattern,
              required customDays,
              required startDate,
              required maxDays,
            }) => testDates,
        validateRecurringSettings: (pattern, days) async {},
        scheduleRecurringNotification:
            ({
              required notificationId,
              required scheduledDate,
              required content,
              required title,
            }) async {},
        scheduleUnattendedAnnouncement: (content, delay) {},
      );

      expect(
        mockSettings.storedTimes.length,
        equals(2),
        reason: 'Should store scheduled time for each notification',
      );
      expect(
        mockSettings.storedTimes[0],
        equals(testDates[0]),
        reason: 'Should store correct time for first notification',
      );
      expect(
        mockSettings.storedTimes[1],
        equals(testDates[1]),
        reason: 'Should store correct time for second notification',
      );
    });

    test(
      'schedules unattended announcement for first occurrence when TTS enabled',
      () async {
        mockSettings.hour = 9;
        mockSettings.minute = 0;

        final now = tz.TZDateTime.now(tz.local);
        final firstDate = now.add(const Duration(hours: 2));
        final testDates = [firstDate, now.add(const Duration(days: 1))];

        await CoreNotificationService.scheduleRecurringNotificationsImpl(
          content: 'Morning announcement',
          recurrencePattern: RecurrencePattern.daily,
          customDays: [],
          config: const AnnouncementConfig(
            enableTTS: true,
            notificationConfig: NotificationConfig(),
          ),
          getAnnouncementHour: mockSettings.getAnnouncementHour,
          getAnnouncementMinute: mockSettings.getAnnouncementMinute,
          setScheduledTimes: mockSettings.setScheduledTimes,
          getRecurringDates:
              ({
                required recurrencePattern,
                required customDays,
                required startDate,
                required maxDays,
              }) => testDates,
          validateRecurringSettings: (pattern, days) async {},
          scheduleRecurringNotification:
              ({
                required notificationId,
                required scheduledDate,
                required content,
                required title,
              }) async {},
          scheduleUnattendedAnnouncement: (content, delay) {
            unattendedAnnouncements.add(
              UnattendedAnnouncementData(content: content, delay: delay),
            );
          },
        );

        expect(
          unattendedAnnouncements.length,
          equals(1),
          reason: 'Should schedule TTS only for first occurrence',
        );
        expect(
          unattendedAnnouncements[0].content,
          equals('Morning announcement'),
          reason: 'TTS content should match announcement content',
        );
      },
    );

    test(
      'does not schedule unattended announcement when TTS disabled',
      () async {
        mockSettings.hour = 9;
        mockSettings.minute = 0;

        final now = tz.TZDateTime.now(tz.local);
        final testDates = [
          now.add(const Duration(hours: 2)),
          now.add(const Duration(days: 1)),
        ];

        await CoreNotificationService.scheduleRecurringNotificationsImpl(
          content: 'Test',
          recurrencePattern: RecurrencePattern.daily,
          customDays: [],
          config: const AnnouncementConfig(
            enableTTS: false,
            notificationConfig: NotificationConfig(),
          ),
          getAnnouncementHour: mockSettings.getAnnouncementHour,
          getAnnouncementMinute: mockSettings.getAnnouncementMinute,
          setScheduledTimes: mockSettings.setScheduledTimes,
          getRecurringDates:
              ({
                required recurrencePattern,
                required customDays,
                required startDate,
                required maxDays,
              }) => testDates,
          validateRecurringSettings: (pattern, days) async {},
          scheduleRecurringNotification:
              ({
                required notificationId,
                required scheduledDate,
                required content,
                required title,
              }) async {},
          scheduleUnattendedAnnouncement: (content, delay) {
            unattendedAnnouncements.add(
              UnattendedAnnouncementData(content: content, delay: delay),
            );
          },
        );

        expect(
          unattendedAnnouncements.length,
          equals(0),
          reason: 'Should not schedule TTS when disabled',
        );
      },
    );

    test('handles empty recurring dates list', () async {
      mockSettings.hour = 10;
      mockSettings.minute = 0;

      await CoreNotificationService.scheduleRecurringNotificationsImpl(
        content: 'Test',
        recurrencePattern: RecurrencePattern.custom,
        customDays: [1],
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        getAnnouncementHour: mockSettings.getAnnouncementHour,
        getAnnouncementMinute: mockSettings.getAnnouncementMinute,
        setScheduledTimes: mockSettings.setScheduledTimes,
        getRecurringDates:
            ({
              required recurrencePattern,
              required customDays,
              required startDate,
              required maxDays,
            }) => [],
        validateRecurringSettings: (pattern, days) async {},
        scheduleRecurringNotification:
            ({
              required notificationId,
              required scheduledDate,
              required content,
              required title,
            }) async {
              scheduledNotifications.add(
                ScheduledNotificationData(
                  id: notificationId,
                  date: scheduledDate,
                  content: content,
                  title: title,
                ),
              );
            },
        scheduleUnattendedAnnouncement: (content, delay) {},
      );

      expect(
        scheduledNotifications.length,
        equals(0),
        reason: 'Should not schedule any notifications when no dates returned',
      );
      expect(
        mockSettings.storedTimes.length,
        equals(0),
        reason: 'Should not store any times when no dates returned',
      );
    });
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

        final announcement = ScheduledAnnouncement(
          id: '1',
          content: 'Morning reminder',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        final existingAnnouncements = <ScheduledAnnouncement>[];

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

        final announcement = ScheduledAnnouncement(
          id: '2',
          content: 'Afternoon reminder',
          scheduledTime: DateTime(2025, 11, 20, 14, 0),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        // 4 existing announcements on the same day + 1 on a different day
        final sameDay = DateTime(2025, 11, 20, 9, 0);
        final existingAnnouncements = [
          ScheduledAnnouncement(
            id: '0',
            content: 'Existing 0',
            scheduledTime: sameDay,
            isActive: true,
          ),
          ScheduledAnnouncement(
            id: '1',
            content: 'Existing 1',
            scheduledTime: sameDay.add(const Duration(hours: 1)),
            isActive: true,
          ),
          ScheduledAnnouncement(
            id: '2',
            content: 'Existing 2',
            scheduledTime: sameDay.add(const Duration(hours: 2)),
            isActive: true,
          ),
          ScheduledAnnouncement(
            id: '3',
            content: 'Existing 3',
            scheduledTime: sameDay.add(const Duration(hours: 3)),
            isActive: true,
          ),
          ScheduledAnnouncement(
            id: '4',
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

        final announcement = ScheduledAnnouncement(
          id: '3',
          content: 'Weekly reminder',
          scheduledTime: DateTime.now().add(const Duration(days: 7)),
          isActive: true,
          recurrence: RecurrencePattern.weekdays,
        );

        // 49 existing announcements across various days
        final existingAnnouncements = List.generate(
          49,
          (i) => ScheduledAnnouncement(
            id: i.toString(),
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

        final announcement = ScheduledAnnouncement(
          id: '4',
          content: 'One too many',
          scheduledTime: DateTime(2025, 11, 20, 16, 0),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        // 3 announcements already scheduled for the same day
        final sameDay = DateTime(2025, 11, 20, 9, 0);
        final existingAnnouncements = [
          ScheduledAnnouncement(
            id: '0',
            content: 'Existing 0',
            scheduledTime: sameDay,
            isActive: true,
          ),
          ScheduledAnnouncement(
            id: '1',
            content: 'Existing 1',
            scheduledTime: sameDay.add(const Duration(hours: 2)),
            isActive: true,
          ),
          ScheduledAnnouncement(
            id: '2',
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

        final announcement = ScheduledAnnouncement(
          id: '5',
          content: 'Too many total',
          scheduledTime: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
          recurrence: RecurrencePattern.daily,
        );

        // 50 announcements already scheduled
        final existingAnnouncements = List.generate(
          50,
          (i) => ScheduledAnnouncement(
            id: i.toString(),
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
