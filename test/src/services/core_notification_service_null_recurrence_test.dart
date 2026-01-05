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

  group('CoreNotificationService Null Recurrence Tests', () {
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
      'scheduleRecurringAnnouncement with null recurrence schedules one-time notification',
      () async {
        // Act
        await service.scheduleRecurringAnnouncement(
          id: 123,
          content: 'Test',
          announcementTime: const TimeOfDay(hour: 10, minute: 0),
          recurrence: null,
        );

        // Assert
        // We expect a call to zonedSchedule WITHOUT matchDateTimeComponents (or null)
        // This ensures it is a one-time notification.

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

        verification.called(1);
        final capturedComponent =
            verification.captured[0] as DateTimeComponents?;

        // It should be null for one-time notification
        expect(
          capturedComponent,
          isNull,
          reason:
              'One-time notification should not have matchDateTimeComponents',
        );
      },
    );
  });
}
