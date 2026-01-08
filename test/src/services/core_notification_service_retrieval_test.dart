import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/notification_scheduler.dart';
import 'package:notification_scheduler/src/services/core_notification_service.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';

import 'core_notification_service_retrieval_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  FlutterTts,
  SchedulingSettingsService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - getScheduledAnnouncements', () {
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
        enableDebugLogging: true, // Enable logging to test debug paths
      );

      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
        notifications: mockNotifications,
        tts: mockTts,
      );
    });

    test(
      'retrieves announcements and filters based on pending notifications',
      () async {
        // Arrange
        final announcement1 = ScheduledNotification(
          id: 1,
          content: 'Test 1',
          scheduledTime: DateTime.now(),
          isActive: true,
        );
        final announcement2 = ScheduledNotification(
          id: 2,
          content: 'Test 2',
          scheduledTime: DateTime.now(),
          isActive: true,
        );

        when(
          mockSettingsService.getScheduledAnnouncements(),
        ).thenAnswer((_) async => [announcement1, announcement2]);

        // Only notification 1 is pending
        when(mockNotifications.pendingNotificationRequests()).thenAnswer(
          (_) async => [
            const PendingNotificationRequest(1, 'title', 'body', 'payload'),
          ],
        );

        when(
          mockSettingsService.removeScheduledAnnouncements(any),
        ).thenAnswer((_) async => {});

        // Act
        final result = await service.getScheduledAnnouncements();

        // Assert
        expect(result.length, 1, reason: 'Should return only 1 announcement');
        expect(
          result.first.id,
          1,
          reason: 'Should return the active announcement',
        );

        // Verify calls
        verify(mockSettingsService.getScheduledAnnouncements()).called(1);
        verify(mockNotifications.pendingNotificationRequests()).called(1);
      },
    );

    test('cleans up stale announcements (stored but not pending)', () async {
      // Arrange
      final announcement1 = ScheduledNotification(
        id: 1,
        content: 'Active',
        scheduledTime: DateTime.now(),
        isActive: true,
      );
      final announcement2 = ScheduledNotification(
        id: 2,
        content: 'Stale',
        scheduledTime: DateTime.now(),
        isActive: true,
      );

      when(
        mockSettingsService.getScheduledAnnouncements(),
      ).thenAnswer((_) async => [announcement1, announcement2]);

      // Only notification 1 is pending
      when(mockNotifications.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(1, 'title', 'body', 'payload'),
        ],
      );

      when(
        mockSettingsService.removeScheduledAnnouncements(any),
      ).thenAnswer((_) async => {});

      // Act
      await service.getScheduledAnnouncements();

      // Assert
      verify(mockSettingsService.removeScheduledAnnouncements([2])).called(1);
    });

    test('handles orphan notifications (pending but not stored)', () async {
      // Arrange
      final announcement1 = ScheduledNotification(
        id: 1,
        content: 'Active',
        scheduledTime: DateTime.now(),
        isActive: true,
      );

      when(
        mockSettingsService.getScheduledAnnouncements(),
      ).thenAnswer((_) async => [announcement1]);

      // Notification 1 and 99 (orphan) are pending
      when(mockNotifications.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(1, 'title', 'body', 'payload'),
          const PendingNotificationRequest(99, 'orphan', 'body', 'payload'),
        ],
      );

      when(
        mockSettingsService.removeScheduledAnnouncements(any),
      ).thenAnswer((_) async => {});

      // Act
      final result = await service.getScheduledAnnouncements();

      // Assert
      expect(
        result.length,
        1,
        reason: 'Should return only stored announcements',
      );
      expect(
        result.first.id,
        1,
        reason: 'Should return the matched announcement',
      );

      // Orphan detection is mainly for logging, so we verify no crash and correct return
    });

    test(
      'cleans up all announcements when no pending notifications exist',
      () async {
        // Arrange
        final announcement1 = ScheduledNotification(
          id: 1,
          content: 'Stale 1',
          scheduledTime: DateTime.now(),
          isActive: true,
        );
        final announcement2 = ScheduledNotification(
          id: 2,
          content: 'Stale 2',
          scheduledTime: DateTime.now(),
          isActive: true,
        );

        when(
          mockSettingsService.getScheduledAnnouncements(),
        ).thenAnswer((_) async => [announcement1, announcement2]);

        // No pending notifications
        when(
          mockNotifications.pendingNotificationRequests(),
        ).thenAnswer((_) async => []);

        when(
          mockSettingsService.removeScheduledAnnouncements(any),
        ).thenAnswer((_) async => {});

        // Act
        final result = await service.getScheduledAnnouncements();

        // Assert
        expect(result, isEmpty, reason: 'Should return empty list');
        verify(
          mockSettingsService.removeScheduledAnnouncements([1, 2]),
        ).called(1);
      },
    );

    test('sorts announcements by scheduled time', () async {
      // Arrange
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));
      final earlier = now.subtract(const Duration(hours: 1));

      final announcement1 = ScheduledNotification(
        id: 1,
        content: 'Later',
        scheduledTime: later,
        isActive: true,
      );
      final announcement2 = ScheduledNotification(
        id: 2,
        content: 'Earlier',
        scheduledTime: earlier,
        isActive: true,
      );
      final announcement3 = ScheduledNotification(
        id: 3,
        content: 'Now',
        scheduledTime: now,
        isActive: true,
      );

      when(
        mockSettingsService.getScheduledAnnouncements(),
      ).thenAnswer((_) async => [announcement1, announcement2, announcement3]);

      // All are pending
      when(mockNotifications.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(1, 'title', 'body', 'payload'),
          const PendingNotificationRequest(2, 'title', 'body', 'payload'),
          const PendingNotificationRequest(3, 'title', 'body', 'payload'),
        ],
      );

      when(
        mockSettingsService.removeScheduledAnnouncements(any),
      ).thenAnswer((_) async => {});

      // Act
      final result = await service.getScheduledAnnouncements();

      // Assert
      expect(result.length, 3, reason: 'Should return all announcements');
      expect(result[0].id, 2, reason: 'First should be earlier');
      expect(result[1].id, 3, reason: 'Second should be now');
      expect(result[2].id, 1, reason: 'Third should be later');
    });
  });
}
