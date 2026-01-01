import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:announcement_scheduler/src/services/core_notification_service.dart';
import 'package:announcement_scheduler/src/services/scheduling_settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
        final announcement1 = ScheduledAnnouncement(
          id: 1,
          content: 'Test 1',
          scheduledTime: DateTime.now(),
          isActive: true,
        );
        final announcement2 = ScheduledAnnouncement(
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
        expect(result.length, 1);
        expect(result.first.id, 1);

        // Verify calls
        verify(mockSettingsService.getScheduledAnnouncements()).called(1);
        verify(mockNotifications.pendingNotificationRequests()).called(1);
      },
    );
  });
}
