import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:announcement_scheduler/src/services/core_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core_notification_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  group('CoreNotificationService Recurrence Tests', () {
    late MockSchedulingSettingsService mockSettingsService;
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late CoreNotificationService service;

    setUp(() {
      mockSettingsService = MockSchedulingSettingsService();
      mockNotifications = MockFlutterLocalNotificationsPlugin();

      // Mock settings
      when(
        mockSettingsService.getAnnouncementHour(),
      ).thenAnswer((_) async => 10);
      when(
        mockSettingsService.getAnnouncementMinute(),
      ).thenAnswer((_) async => 0);
      when(
        mockSettingsService.getScheduledAnnouncements(),
      ).thenAnswer((_) async => []);
      when(
        mockSettingsService.addScheduledAnnouncement(any),
      ).thenAnswer((_) async {});
      when(
        mockSettingsService.setAnnouncementTime(any, any),
      ).thenAnswer((_) async {});

      // Mock notifications
      when(
        mockNotifications.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);
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

      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
        ),
        notifications: mockNotifications,
      );
    });

    test(
      'scheduleRecurringAnnouncement with daily recurrence schedules multiple daily repeating notifications',
      () async {
        // Act
        final returnedId = await service.scheduleRecurringAnnouncement(
          id: 123,
          content: 'Test',
          announcementTime: const TimeOfDay(hour: 10, minute: 0),
          recurrence: RecurrencePattern.daily,
        );

        expect(returnedId, 123);

        // Assert
        // We expect a single call to zonedSchedule with DateTimeComponents.time
        // This ensures the notification repeats daily without creating duplicates.

        final verification = verify(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: captureAnyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        );

        verification.called(
          1,
        ); // It should be called 1 time for daily recurrence

        // Check that matchDateTimeComponents was DateTimeComponents.time
        final captured = verification.captured;
        expect(captured.first, equals(DateTimeComponents.time));

        // If this passes, it confirms the fix: only one notification is scheduled,
        // which repeats daily.
      },
    );

    test(
      'scheduleRecurringAnnouncement with weekdays recurrence schedules 5 weekly repeating notifications',
      () async {
        // Act
        await service.scheduleRecurringAnnouncement(
          id: 124,
          content: 'Test Weekdays',
          announcementTime: const TimeOfDay(hour: 10, minute: 0),
          recurrence: RecurrencePattern.weekdays,
        );

        // Assert
        final verification = verify(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: captureAnyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        );

        verification.called(5); // Mon, Tue, Wed, Thu, Fri

        final captured = verification.captured;
        for (final component in captured) {
          expect(component, equals(DateTimeComponents.dayOfWeekAndTime));
        }
      },
    );
  });
}
