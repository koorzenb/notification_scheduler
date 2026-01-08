import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/notification_scheduler.dart';
import 'package:notification_scheduler/src/services/core_notification_service.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';

import 'core_notification_service_cancellation_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  FlutterTts,
  SchedulingSettingsService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - cancelAnnouncementById', () {
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

    test('cancels notification on platform and removes from storage', () async {
      // Arrange
      const announcementId = 123;
      when(mockNotifications.cancel(any)).thenAnswer((_) async {});
      when(
        mockSettingsService.removeScheduledAnnouncement(any),
      ).thenAnswer((_) async {});

      // Act
      await service.cancelAnnouncementById(announcementId);

      // Assert
      verify(mockNotifications.cancel(announcementId)).called(1);
      verify(
        mockSettingsService.removeScheduledAnnouncement(announcementId),
      ).called(1);
    });

    test('handles errors gracefully', () async {
      // Arrange
      const announcementId = 123;
      when(
        mockNotifications.cancel(any),
      ).thenThrow(Exception('Platform error'));

      // Act & Assert
      expect(
        () => service.cancelAnnouncementById(announcementId),
        throwsA(isA<NotificationSchedulingException>()),
        reason:
            'Should throw NotificationSchedulingException on platform error',
      );
    });
  });
}
