import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/notification_scheduler.dart';
import 'package:notification_scheduler/src/services/core_notification_service.dart';

import 'core_notification_service_retrieval_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - Cleanup Logic', () {
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late MockFlutterTts mockTts;
    late MockSchedulingSettingsService mockSettingsService;
    late CoreNotificationService service;
    late AnnouncementConfig config;

    setUp(() {
      mockNotifications = MockFlutterLocalNotificationsPlugin();
      mockTts = MockFlutterTts();
      mockSettingsService = MockSchedulingSettingsService();
      config = const AnnouncementConfig(
        enableTTS: true,
        notificationConfig: NotificationConfig(),
        enableDebugLogging: true,
      );

      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
        notifications: mockNotifications,
        tts: mockTts,
      );

      // Stub TTS methods
      when(mockTts.speak(any)).thenAnswer((_) async => 1);
      when(mockTts.stop()).thenAnswer((_) async => 1);
    });

    tearDown(() {
      service.dispose();
    });

    test(
      'cleanup is triggered when AnnouncementStatus.completed is emitted',
      () async {
        // Arrange
        final announcement1 = ScheduledNotification(
          id: 1,
          content: 'Announcement 1',
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          isActive: true,
        );
        final announcement2 = ScheduledNotification(
          id: 2,
          content: 'Announcement 2',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
          isActive: true,
        );

        // Storage has both announcements
        when(
          mockSettingsService.getScheduledAnnouncements(),
        ).thenAnswer((_) async => [announcement1, announcement2]);

        // Platform only has announcement 2 (announcement 1 completed)
        when(mockNotifications.pendingNotificationRequests()).thenAnswer(
          (_) async => [
            const PendingNotificationRequest(2, 'Title', 'Body', 'Payload'),
          ],
        );

        // Mock removal
        when(
          mockSettingsService.removeScheduledAnnouncements(any),
        ).thenAnswer((_) async => {});

        // Act
        // Simulate notification response which emits AnnouncementStatus.completed
        service.onNotificationResponse(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 1,
            payload: 'Payload',
          ),
        );

        // Wait for async cleanup to complete
        // The listener is async, and _cleanupCompletedAnnouncements is async
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        // Verify that getScheduledAnnouncements was called (part of reconciliation)
        verify(mockSettingsService.getScheduledAnnouncements()).called(1);

        // Verify that pendingNotificationRequests was called
        verify(mockNotifications.pendingNotificationRequests()).called(1);

        // Verify that removeScheduledAnnouncements was called with ID 1
        verify(mockSettingsService.removeScheduledAnnouncements([1])).called(1);
      },
    );

    test('cleanup does not remove active announcements', () async {
      // Arrange
      final announcement1 = ScheduledNotification(
        id: 1,
        content: 'Announcement 1',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        isActive: true,
      );

      // Storage has announcement 1
      when(
        mockSettingsService.getScheduledAnnouncements(),
      ).thenAnswer((_) async => [announcement1]);

      // Platform has announcement 1
      when(mockNotifications.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(1, 'Title', 'Body', 'Payload'),
        ],
      );

      // Act
      service.onNotificationResponse(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'Payload',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(mockSettingsService.getScheduledAnnouncements()).called(1);
      verify(mockNotifications.pendingNotificationRequests()).called(1);
      // Should NOT call removeScheduledAnnouncements
      verifyNever(mockSettingsService.removeScheduledAnnouncements(any));
    });
  });
}
